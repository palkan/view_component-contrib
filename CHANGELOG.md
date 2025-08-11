# Change log

## master

## 0.2.5 (2025-08-11)

- Fix compatibility with view_component v4.

## 0.2.4 (2025-01-03)

- Add inheritance strategies to style variants ([@omarluq][])

- Add special `class:` variant to `style` helper. For appending classes.
  Inspired by https://cva.style/docs/getting-started/extending-components

## 0.2.3 (2024-07-31)

- Fix publishing transpiled files (and bring Ruby 2.7 support back) ([@palkan][])

## 0.2.2 (2023-11-29)

- Add `compound` styles support. ([@palkan][])

- Support using booleans as style variant values. ([@palkan][])

## 0.2.1 (2023-11-16)

- Fix style variants inhertiance. ([@palkan][])

## 0.2.0 (2023-11-07)

- Introduce style variants. ([@palkan][])

- **Require Ruby 2.7+**. ([@palkan][])

- Add system tests to generator. ([@palkan][])

- Drop Webpack-related stuff from the generator. ([@palkan][])

## 0.1.6 (2023-11-07)

- Support preview classes named `<component|partial>_preview.rb`. ([@palkan][])

It's also possible to explicitly specify the component class name for the preview class:

```ruby
class MyComponentPreview
  self.component_class_name = "SomeComponent"

  def default
    render_component
  end
end
```

## 0.1.5 (2023-11-02)

- Support content blocks in `#render_component` and `#render_with`. ([@palkan][])

```ruby
class MyComponent::Preview
  def default
    # Now you can pass a block to render_component to render it inside the component:
    render_component(kind: "info") do
      "Welcome!"
    end
  end
end
```

- Support implicit components in `#render_component` helper. ([@palkan][])

```ruby
class MyComponent::Preview
  def default
    # Before
    render_component(MyComponent::Component.new(foo: "bar"))
  end

  # After
  def default
    render_component(foo: "bar")
  end
end
```

## 0.1.4 (2023-04-30)

- Fix compatibility with new errors classes in view_component.

See [view_component#1701](https://github.com/ViewComponent/view_component/pull/1701).

## 0.1.3 (2023-02-02)

- Fix release dependencies ([@palkan][])

## 0.1.2 (2023-01-13)

- Fix compatibility with sidecar translations. ([@palkan][])

- Detect Webpack when using Rails 7 + jsbundling-rails. ([@unikitty37][])

- Skip autoloading of Preview files when viewing previews is disabled. ([@dhnaranjo][])

- Automatic publish to RailsBytes in CI. ([@fargelus][])

## 0.1.1 (2022-03-14)

- Fix adding gem's previews to the app's path. ([@palkan][])

- Fix configurable default template.

## 0.1.0 (2021-04-07)

- Initial release.

[@palkan]: https://github.com/palkan
[@fargelus]: https://github.com/fargelus
[@dhnaranjo]: https://github.com/dhnaranjo
