[![Gem Version](https://badge.fury.io/rb/view_component-contrib.svg)](https://rubygems.org/gems/view_component-contrib)
[![Build](https://github.com/palkan/view_component-contrib/workflows/Build/badge.svg)](https://github.com/palkan/view_component-contrib/actions)

# View Component: extensions, examples and development tools

This repository contains various code snippets and examples related to the [ViewComponent][] library. The goal of this project is to share common patterns and practices which we found useful while working on different projects (and which haven't been or couldn't be proposed to the upstream).

All extensions and patches are packed into a `view_component-contrib` _meta-gem_. So, to use them add to your Gemfile:

```ruby
gem "view_component-contrib"
```

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Installation and generating generators

**NOTE:** We highly recommend to walk through this document before running the generator.

The easiest way to start using `view_component-contrib` extensions and patterns is to run an interactive generator (a custom [Rails template][railsbytes-template]).

All you need to do is to run:

```sh
rails app:template LOCATION="https://railsbytes.com/script/zJosO5"
```

The command above:

- Installs `view_component-contrib` gem.
- Configure `view_component` paths.
- Adds `ApplicationViewComponent` and `ApplicationViewComponentPreview` classes.
- Configures testing framework (RSpec or Minitest).
- **Adds a custom generator to create components**.

The custom generator would allow you to create all the required component files in a single command:

```sh
bundle exec rails g view_component Example

# see all available options
bundle exec rails g view_component -h
```

**Why adding a custom generator to the project instead of bundling it into the gem?** The generator could only be useful if it fits
your project needs. The more control you have over the generator the better. Thus, the best way is to make the generator a part of a project.

> [!IMPORTANT]
> If your application has the `lib/` folder in the autoload paths, make sure you ignored the generated `lib/generators` folder. In Rails 7.1+, you can do this via adding `generators` the `config.autoload_lib` call's `ignore` option. Before, you can use `Rails.autoloaders.main.ignore(...)`.

## Organizing components, or sidecar pattern extended

ViewComponent provides different ways to organize your components: putting everyhing (Ruby files, templates, etc.) into `app/components` folder or using a _sidecar_ directory for everything but the `.rb` file itself. The first approach could easily result in a directory bloat; the second is better though there is a room for improvement: we can move `.rb` files into sidecar folders as well. Then, we can get rid of the _noisy_ `_component` suffixes. Finally, we can also put previews there (since storing them within the test folder is a little bit confusing):

```txt
components/                                 components/
  example_component/                          example/
    example_component.html                       component.html
  example_component.rb              →            component.rb
test/                                            preview.rb
  components/                                    index.css
    previews/                                    index.js
      example_component_preview.rb
```

Thus, everything related to a particular component (except tests, at least for now) is located within a single folder.

The two base classes are added to follow the Rails way: `ApplicationViewComponent` and `ApplicationViewComponentPreview`.

We also put the `components` folder into the `app/frontend` folder, because `app/components` is too general and could be used for other types of components, not related to the view layer.

Here is an example Rails configuration:

```ruby
config.autoload_paths << Rails.root.join("app", "frontend", "components")
```

### Organizing previews

First, we need to specify the lookup path for previews in the app's configuration:

```ruby
# view_component >= v4
config.view_component.previews.paths << Rails.root.join("app", "frontend", "components")

# view_component <= v3
config.view_component.preview_paths << Rails.root.join("app", "frontend", "components")
```

By default, ViewComponent requires preview files to have `_preview.rb` suffix, and it's not configurable (yet). To overcome this, we have to patch the `ViewComponent::Preview` class:

```ruby
# you can put this into an initializer
ActiveSupport.on_load(:view_component) do
  ViewComponent::Preview.extend ViewComponentContrib::Preview::Sidecarable
end
```

You can still continue using preview clases with the `_preview.rb` suffix, they would work as before.

#### Reducing previews boilerplate

In most cases, previews contain only the `default` example and a very simple template (`= render Component.new(**options)`).
We provide a `ViewComponentContrib::Preview` class, which helps to reduce the boilerplate by re-using templates and providing a handful of helpers.

The default template shipped with the gem is as follows:

```erb
<div class="<%= container_class %>">
  <%- if component -%>
    <%= render component %>
  <%- else -%>
    Failed to infer a component from the preview: <%= error %>
  <%- end -%>
</div>
```

To define your own default template:
```ruby
class ApplicationViewComponentPreview < ViewComponentContrib::Preview::Base
  # ...
  self.default_preview_template = "path/to/your/template.html.{erb,haml,slim}"
  # ...
end
```

Let's assume that you have the following `ApplicationViewComponentPreview`:

```ruby
class ApplicationViewComponentPreview < ViewComponentContrib::Preview::Base
  # Do not show this class in the previews index
  self.abstract_class = true
end
```

It allows to render a component instances within a configurable container. The component could be either created explicitly in the preview action:

```ruby
class Banner::Preview < ApplicationViewComponentPreview
  def default
    render_component Banner::Component.new(text: "Welcome!")
  end
end
```

Or implicitly:

```ruby
class LikeButton::Preview < ApplicationViewComponentPreview
  def default
    # Nothing here; the preview class would try to build a component automatically
    # calling `LikeButton::Component.new`
  end
end
```

To provide the container class, you should either specify it in the preview class itself or within a particular action by calling `#render_with`:

```ruby
class Banner::Preview < ApplicationViewComponentPreview
  self.container_class = "absolute w-full"

  def default
    # This will use `absolute w-full` for the container class
    render_component Banner::Component.new(text: "Welcome!")

    # or even shorter
    render_component(text: "Welcome!")

    # you can also pass a content block
    render_component(kind: :notice) do
      "Some content"
    end
  end

  def mobile
    render_with(
      component: Banner::Component.new(text: "Welcome!").with_variant(:mobile),
      container_class: "w-25"
    )
  end
end
```

If you need more control over your template, you can add a custom `preview.html.*` template (which will be used for all examples in this preview), or even create an example-specific `previews/example.html.*` (e.g. `previews/mobile.html.erb`).

## Style variants

Since v0.2.0, we provide a custom extentions to manage CSS classes and their combinations—**Style Variants**. This is especially useful for project using CSS frameworks such as TailwindCSS.

The idea is to define variants schema in the component class and use it to compile the resulting list of CSS classes. (Inspired by [Tailwind Variants](https://www.tailwind-variants.org) and [CVA variants](https://cva.style/docs/getting-started/variants)).

Consider an example:

```ruby
class ButtonComponent < ViewComponent::Base
  include ViewComponentContrib::StyleVariants

  style do
    base {
      %w[
        font-medium bg-blue-500 text-white rounded-full
      ]
    }
    variants {
      color {
        primary { %w[bg-blue-500 text-white] }
        secondary { %w[bg-purple-500 text-white] }
      }
      size {
        sm { "text-sm" }
        md { "text-base" }
        lg { "px-4 py-3 text-lg" }
      }
      disabled {
        yes { "opacity-75" }
      }
    }
    defaults { {size: :md, color: :primary} }
  end

  attr_reader :size, :color, :disabled

  def initialize(size: nil, color: nil, disabled: false)
    @size = size
    @color = color
    @disabled = disabled
  end
end
```

Now, in the template, you can use the `#style` method and pass the variants to it:

```erb
<button class="<%= style(size:, color:) %>">Click me</button>
```

Passing `size: :lg` and `color: :secondary` would result in the following HTML:

```html
<button class="font-medium bg-purple-500 text-white rounded-full px-4 py-3 text-lg">Click me</button>
```

The `true` / `false` variant value would be converted into the `yes` / `no` variants:

```erb
<button class="<%= style(size:, color:, disabled: true) %>">Click me</button>
```

**NOTE:** If you pass `nil`, the default value would be used.

You can define multiple style sets in a single component:

```ruby
class ButtonComponent < ViewComponent::Base
  include ViewComponentContrib::StyleVariants

  # default component styles
  style do
    # ...
  end

  style :image do
    variants {
      orient {
        portrait { "w-32 h-32" }
        landscape { "w-64 h-32" }
      }
    }
  end
end
```

And in the template:

```erb
<div>
  <button class="<%= style(size:, theme:) %>">Click me</button>
  <img src="..." class="<%= style(:image, orient: :portrait) %>">
</div>
```

You can also add additional classes through thr `style` method using the special `class:` variant, like so:

```erb
<div>
  <button class="<%= style(size:, theme:, class: 'extra-class') %>">Click me</button>
  <img src="..." class="<%= style(:image, orient: :portrait) %>">
</div>
```

Finally, you can inject into the class list compilation process to add your own logic:

```ruby
class ButtonComponent < ViewComponent::Base
  include ViewComponentContrib::StyleVariants

  # You can provide either a proc or any other callable object
  style_config.postprocess_with do |classes|
    # classes is an array of CSS classes
    # NOTE: This is an abstract TailwindMerge class, not to be confused with existing libraries
    TailwindMerge.call(classes).join(" ")
  end
end
```

### Style variants inheritance

Style variants support three inheritance strategies when extending components:

1. `override` (default behavior): Completely replaces parent variants.
2. `merge` (deep merge): Preserves all variant keys unless explicitly overwritten.
3. `extend` (shallow merge): Preserves variants unless explicitly overwritten.

Consider an example:

```ruby
class Parent::Component < ViewComponent::Base
  include ViewComponentContrib::StyleVariants

  style do
    variants do
      size {
        md { "text-md" }
        lg { "text-lg" }
      }
      disabled {
        yes { "opacity-50" }
      }
    end
  end
end

# Using override strategy (default)
class Child::Component < Parent::Component
  style do
    variants do
      size {
        lg { "text-larger" }
      }
    end
  end
end

# Using merge strategy
class Child::Component < Parent::Component
  style do
    variants(strategy: :merge) do
      size {
        lg { "text-larger" }
      }
    end
  end
end

# Using extend strategy
class Child::Component < Parent::Component
  style do
    variants(strategy: :extend) do
      size {
        lg { "text-larger" }
      }
    end
  end
end
```

In this example, the `override` strategy will only keep the `size.lg` variant, dropping all others. The `merge` strategy preserves all variants and their keys, only replacing the `size.lg` value. The `extend` strategy keeps all variants but replaces all keys of the overwritten `size` variant.

### Dependent (or compound) styles

Sometimes it might be necessary to define complex styling rules, e.g., when a combination of variants requires adding additional styles. That's where usage of Ruby blocks for configuration becomes useful. For example:

```ruby
style do
  variants {
    size {
      sm { "text-sm" }
      md { "text-base" }
      lg { "px-4 py-3 text-lg" }
    }
    theme {
      primary do |size:, **|
        %w[bg-blue-500 text-white].tap do
          _1 << "uppercase" if size == :lg
        end
      end
      secondary { %w[bg-purple-500 text-white] }
    }
  }
end
```

The specified variants are passed as block arguments, so you can implement dynamic styling.

If you prefer declarative approach, you can use the special `compound` directive. The previous example could be rewritten as follows:

```ruby
style do
  variants {
    size {
      sm { "text-sm" }
      md { "text-base" }
      lg { "px-4 py-3 text-lg" }
    }
    theme {
      primary { %w[bg-blue-500 text-white] }
      secondary { %w[bg-purple-500 text-white] }
    }
  }

  compound(size: :lg, theme: :primary) { %w[uppercase] }
end
```

### Using with TailwindCSS LSP

To make completions (and other LSP features) work with our DSL, try the following configuration:

```json
"tailwindCSS.includeLanguages": {
  "erb": "html",
  "ruby": "html"
},
"tailwindCSS.experimental.classRegex": [
  "%w\\[([^\\]]*)\\]"
]
```

**NOTE:** It will only work with `%w[ ... ]` word arrays, but you can adjust it to your needs.

## Organizing assets (JS, CSS)

**NOTE**: This section assumes the usage of Vite or Webpack. See [this discussion](https://github.com/palkan/view_component-contrib/discussions/14) for other options.

We store JS and CSS files in the same sidecar folder:

```txt
components/
  example/
    component.html
    component.rb
    index.css
    index.js
```

The `index.js` is the controller's entrypoint; it imports the CSS file and may contain some JS code:

```js
import "./index.css"
```

In the root of the `components` folder we have the `index.js` file, which loads all the components:

- With Vite:

```js
// With Vite
import.meta.glob("./**/index.js").forEach((path) => {
  const mod = await import(path);
  mod.default();
});
```

- With Webpack:

```js
// components/index.js
const context = require.context(".", true, /index.js$/)
context.keys().forEach(context);
```

### Using with StimulusJS

You can define Stimulus controllers right in the component folder in the `controller.js` file:

```js
// We reserve Controller for the export name
import { Controller as BaseController } from "@hotwired/stimulus";

export class Controller extends BaseController {
  connect() {
    // ...
  }
}
```

Then, in your Stimulus entrypoint, you can load and register your component controllers as follows:

- With Vite:

```js
import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

// Generic controllers
const genericControllers = import.meta.globEager(
  "../controllers/**/*_controller.js"
);

for (let path in genericControllers) {
  let module = genericControllers[path];
  let name = path
    .match(/controllers\/(.+)_controller\.js$/)[1]
    .replaceAll("/", "-")
    .replaceAll("_", "-");

  application.register(name, module.default);
}

// Controllers from components
const controllers = import.meta.globEager(
  "./../../app/frontend/components/**/controller.js"
);

for (let path in controllers) {
  let module = controllers[path];
  let name = path
    .match(/app\/frontend\/components\/(.+)\/controller\.js$/)[1]
    .replaceAll("/", "-")
    .replaceAll("_", "-");
  application.register(name, module.default);
}

export default application;
```

- With Webpack:

```js
import { Application } from "stimulus";
export const application = Application.start();

// ... other controllers

const context = require.context("./../../app/frontend/components/", true, /controllers.js$/)
context.keys().forEach((path) => {
  const mod = context(path);

  // Check whether a module has the Controller export defined
  if (!mod.Controller) return;

  // Convert path into a controller identifier:
  //   example/index.js -> example
  //   nav/user_info/index.js -> nav--user-info
  const identifier = path
    .match(/app\/frontend\/components\/(.+)\/controller\.js$/)[1]
    .replaceAll("/", "-")
    .replaceAll("_", "-");

  application.register(identifier, mod.Controller);
});
```

We also can add a helper to our base ViewComponent class to generate the controller identifier following the convention above:

```ruby
class ApplicationViewComponent
  private

  def identifier
    @identifier ||= self.class.name.sub("::Component", "").underscore.split("/").join("--")
  end

  alias_method :controller_name, :identifier
end
```

And now in your template:

```erb
<!-- component.html -->
<div data-controller="<%= controller_name %>">
</div>
```

### Isolating CSS with postcss-modules

Our JS code is isolated by design but our CSS is still global. Hence we should care about naming, use some convention (such as BEM) or whatever.

Alternatively, we can leverage the power of modern frontend technologies such as [CSS modules][] via [postcss-modules][] plugin. It allows you to use _local_ class names in your component, and takes care of generating unique names in build time. We can configure PostCSS Modules to follow our naming convention, so, we can generate the same unique class names in both JS and Ruby.

First, install the `postcss-modules` plugin (`yarn add postcss-modules`).

Then, add the following to your `postcss.config.js`:

```js
module.exports = {
  plugins: {
    'postcss-modules': {
      generateScopedName: (name, filename, _css) => {
        const matches = filename.match(/\/app\/frontend\/components\/?(.*)\/index.css$/);
        // Do not transform CSS files from outside of the components folder
        if (!matches) return name;

        // identifier here is the same identifier we used for Stimulus controller (see above)
        const identifier = matches[1].replace("/", "--");

        // We also add the `c-` prefix to all components classes
        return `c-${identifier}-${name}`;
      },
      // Do not generate *.css.json files (we don't use them)
      getJSON: () => {}
    },
    /// other plugins
  },
}
```

Finally, let's add a helper to our view components:

```ruby
class ApplicationViewComponent
  private

  # the same as above
  def identifier
    @identifier ||= self.class.name.sub("::Component", "").underscore.split("/").join("--")
  end

  # We also add an ability to build a class from a different component
  def class_for(name, from: identifier)
    "c-#{from}-#{name}"
  end
end
```

And now in your template:

```erb
<!-- example/component.html -->
<div class="<%= class_for("container") %>">
  <p class="<%= class_for("body") %>"><%= text %></p>
</div>
```

Assuming that you have the following `index.css`:

```css
.container {
  padding: 10px;
  background: white;
  border: 1px solid #333;
}

.body {
  margin-top: 20px;
  font-size: 24px;
}
```

The final HTML output would be:

```html
<div class="c-example-container">
  <p class="c-example-body">Some text</p>
</div>
```

## I18n integration (alternative)

ViewComponent recently added (experimental) [I18n support](https://github.com/github/view_component/pull/660), which allows you to have **isolated** localization files for each component. Isolation rocks, but managing dozens of YML files spread accross the project could be tricky, especially, if you rely on some external localization tool which creates these YMLs for you.

We provide an alternative (and more _classic_) way of dealing with translations—**namespacing**. Following the convention over configuration,
put translations under `<locale>.view_components.<component_scope>` key, for example:

```yml
en:
  view_components:
    login_form:
      submit: "Log in"
    nav:
      user_info:
        login: "Log in"
        logout: "Log out"
```

And then in your components:

```erb
<!-- login_form/component.html.erb -->
<button type="submit"><%= t(".submit") %></button>

<!-- nav/user_info/component.html.erb -->
<a href="/logout"><%= t(".logout") %></a>
```

If you're using `ViewComponentContrib::Base`, you already have translation support included.
Othwerwise you must include the module yourself:

```ruby
class ApplicationViewComponent < ViewComponent::Base
  include ViewComponentContrib::TranslationHelper
end
```

You can override the default namespace (`view_components`) and a particular component _scope_:

```ruby
class ApplicationViewComponent < ViewComponentContrib::Base
  self.i18n_namespace = "my_components"
end

class SomeButton::Component < ApplicationViewComponent
  self.i18n_scope = %w[legacy button]
end
```

## Hanging `#initialize` out to Dry

One way to improve development experience with ViewComponent is to move from imperative `#initialize` to something declarative.
Our choice is [dry-initializer][].

Assuming that we have the following component:

```ruby
class FlashAlert::Component < ApplicationViewComponent
  attr_reader :type, :duration, :body

  def initialize(body:, type: "success", duration: 3000)
    @body = body
    @type = type
    @duration = duration
  end
end
```

Let's add `dry-initializer` to our base class:

```ruby
class ApplicationViewComponent
  extend Dry::Initializer
end
```

And then refactor our FlashAlert component:

```ruby
class FlashAlert::Component < ApplicationViewComponent
  option :type, default: proc { "success" }
  option :duration, default: proc { 3000 }
  option :body
end
```

## Supporting `.with_collection`

The `.with_collection` method from ViewComponent expects a component class to have the "Component" suffix to correctly infer the parameter name. Since we're using a different naming convention, we need to specify the collection parameter name explicitly. For example:

```ruby
class PostCard::Component < ApplicationViewComponent
  with_collection_parameter :post

  option :post
end
```

You can add this to following line to your component generator (unless it's already added): `with_collection_parameter :<%= singular_name %>` to always explicitly provide the collection parameter name.

## Wrapped components

Sometimes we need to wrap a component into a custom HTML container (for positioning or whatever). By default, such wrapping doesn't play well with the `#render?` method because if we don't need a component, we don't need a wrapper.

To solve this problem, we introduce a special `ViewComponentContrib::WrapperComponent` class: it takes any component as the only argument and accepts a block during rendering to define a wrapping HTML. And it renders only if the _inner component_'s `#render?` method returns true.

```erb
<%= render ViewComponentContrib::WrappedComponent.new(Example::Component.new) do |wrapper| %>
  <div class="col-md-auto mb-4">
    <%= wrapper.component %>
  </div>
<%- end -%>
```

You can add a `#wrapped` method to your base class to simplify the code above:

```ruby
class ApplicationViewComponent < ViewComponent::Base
  # adds #wrapped method
  # NOTE: Already included into ViewComponentContrib::Base
  include ViewComponentContrib::WrappedHelper
end
```

And the template looks like this now:

```erb
<%= render Example::Component.new.wrapped do |wrapper| %>
  <div class="col-md-auto mb-4">
    <%= wrapper.component %>
  </div>
<%- end -%>
```

You can use the `#wrapped` method on any component inherited from `ApplicationViewComponent` to wrap it automatically:

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[ViewComponent]: https://github.com/github/view_component
[postcss-modules]: https://github.com/madyankin/postcss-modules
[CSS modules]: https://github.com/css-modules/css-modules
[dry-initializer]: https://dry-rb.org/gems/dry-initializer
[railsbytes-template]: https://railsbytes.com/templates/zJosO5
