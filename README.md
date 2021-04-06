[![Gem Version](https://badge.fury.io/rb/view_component-contrib.svg)](https://rubygems.org/gems/view_component-contrib)
[![Build](https://github.com/palkan/view_component-contrib/workflows/Build/badge.svg)](https://github.com/palkan/view_component-contrib/actions)

# View Component: extensions, examples and development tools

This repository contains various code snippets and examples related to the [ViewComponent][] library. The goal of this project is to share common patterns and practices which we found useful while working on different projects (and which haven't been or couldn't be proposed to the upstream).

All extensions and patches are packed into a `view_component-contrib` _meta-gem_.

## Organizing components, or sidecar pattern extended

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
