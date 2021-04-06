[![Gem Version](https://badge.fury.io/rb/view_component-contrib.svg)](https://rubygems.org/gems/view_component-contrib)
[![Build](https://github.com/palkan/view_component-contrib/workflows/Build/badge.svg)](https://github.com/palkan/view_component-contrib/actions)

# View Component: extensions, examples and development tools

This repository contains various code snippets and examples related to the [ViewComponent][] library. The goal of this project is to share common patterns and practices which we found useful while working on different projects (and which haven't been or couldn't be proposed to the upstream).

All extensions and patches are packed into a `view_component-contrib` _meta-gem_.

## Organizing components, or sidecar pattern extended

ViewComponent provides different ways to organize your components: putting everyhing (Ruby files, templates, etc.) into `app/components` folder or using a _sidecar_ directory for everything but the `.rb` file itself. The first approach could easily result in a directory bloat; the second is better though there is a room for improvement: we can move `.rb` files into sidecar folders as well. Then, we can get rid of the _noisy_ `_component` suffixes. Finally, we can also put previews there (since storing them within the test folder is a little bit confusing):

```txt
components/                                 components/
  example_component/                          example/
    example_component.html                       component.html
  example_component.rb              →            component.rb
test/                                            preview.rb
  components/                                    component.css
    previews/                                    component.js
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
config.view_component.preview_paths << Rails.root.join("app", "frontend", "components")
```

By default, ViewComponent requires preview files to have `_preview.rb` suffix, and it's not configurable (yet). To overcome this, we have to patch the `ViewComponent::Preview` class:

```ruby
# you can put this into an initializer
ActiveSupport.on_load(:view_component) do
  ViewComponent::Preview.extend ViewComponentContrib::Preview::Sidecarable
end
```

#### Reducing previews boilerplate

In most cases, previews contain only the `default` example and a very simple template (`= render Component.new(**options)`).
We provide a `ViewComponentContrib::Preview` class, which helps to reduce the boilerplate by re-using templates and providing a handful of helpers.

The default template shipped with the gem is as follows:

```html
<div class="<%= container_class %>">
  <%= render component %>
</div>
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
  end

  def mobile
    render_with(
      component: Banner::Component.new(text: "Welcome!").with_variant(:mobile),
      container_class: "w-25"
    )
  end
end
```

If you need more control over your template, you can add a custom `preview.html.erb` file.
**NOTE:** We assume that all examples uses the same `preview.html`. If it's not the case,
you can use the original `#render_with_template` method.

## Installation and generating generators

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

## Isolating CSS with postcss-modules

## Wrapped components

## Separating context and arguments

## ToDo list

- Better preview tools (w/o JS deps 😉).
- Hotwire-related extensions.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[ViewComponent]: https://github.com/github/view_component
