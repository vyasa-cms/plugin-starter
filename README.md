# Plugin starter

A working Vyasa plugin, and the path from "it logs a line" to "it is in
the marketplace". Press **Use this template** on GitHub, clone your copy,
and work through the sections in order.

A Vyasa plugin is a **WebAssembly component** that runs in a sandbox. It
can only do what its `manifest.toml` declares — read posts, write to its
own key-value store, fetch one named host — and the server enforces that
list on every call. Operators see the list before they install, which is
why a plugin they do not know is still safe to try.

```text
src/lib.rs        # the plugin: every export of the vyasa-plugin-v2 world
wit/host.wit      # the contract between plugin and host (do not edit)
manifest.toml     # name, version, capabilities
scripts/build.sh  # build → pack → dist/<name>-<version>.vyplugin
```

## 1. Set up

- Rust, with the WebAssembly target this repository pins
  (`rust-toolchain.toml` installs it: `wasm32-wasip2`).
- A Vyasa install to test against — the
  [quick start](https://github.com/vyasa-cms/vyasa#quick-start) runs one
  in Docker — and the `vyasa` binary from a
  [release archive](https://github.com/vyasa-cms/vyasa/releases) on your
  `PATH`.
- A signing key. Every plugin package is signed by its author:

  ```bash
  vyasa plugin keygen        # prints a secret and a public key
  ```

  Keep the secret in your password manager. Tell your local install to
  trust the public half — `VYASA_PACKAGE_TRUSTED_KEYS=<public hex>` in
  the app's environment — and restart it.

## 2. Your first filter

`src/lib.rs` already implements every export with a safe default. Find
`fn filter` and make it do something visible:

```rust
fn filter(stage: FilterStage, content: String) -> String {
    match stage {
        FilterStage::RenderPostHtml => format!("{content}<p><em>Thanks for reading.</em></p>"),
        _ => content,
    }
}
```

Build and pack, then upload:

```bash
VYASA_SIGNING_KEY=<secret hex> scripts/build.sh
# dist/my-plugin-0.1.0.vyplugin
```

**Plugins → Upload** in the admin, confirm the capability list (just
`log:write` so far), then **Enable**. Open any post: the line is there.
Disable it: the line is gone, nothing else changed. That is the whole
lifecycle — install, enable, disable, uninstall — and none of it restarts
the server.

## 3. Read something: a block

To show data, declare the capability and use the host function.
`manifest.toml`:

```toml
capabilities = ["log:write", "db:read:posts"]
```

Then register a block and render it (`register_blocks` and
`render_block` in `src/lib.rs`):

```rust
fn register_blocks() -> String {
    r#"[{"kind":"my-plugin/latest","title":"Latest posts","attrs":{}}]"#.to_owned()
}

fn render_block(kind: String, _attrs_json: String) -> Result<String, String> {
    if kind != "my-plugin/latest" { return Ok(String::new()); }
    let posts = host::query_posts(None, 5)?;
    let items: Vec<String> = posts.iter().map(|p| format!("<li>{}</li>", p.title)).collect();
    Ok(format!("<ul>{}</ul>", items.join("")))
}
```

Bump `version` in `manifest.toml` and `Cargo.toml`, build, upload. The
admin now shows **(new)** next to `db:read:posts` and asks you to accept
it — that is what every operator will see when you widen a plugin's
reach. Authors can place the block from the editor's block picker.

## 4. A route and a setting

`register_routes` declares public URLs under `/plugin/my-plugin/…`;
`handle_request` answers them. `register_admin` declares a settings form
(a JSON schema) and `init` receives what the operator filled in as
`config_json`. The
[contract reference](https://github.com/vyasa-cms/vyasa/blob/main/docs/plugin-api.md)
documents every export, every host function and the capability each one
needs; the
[bookshelf example](https://github.com/vyasa-cms/vyasa/tree/main/plugin-sdk/examples/bookshelf)
uses all of them in about 200 lines.

## 5. Capabilities, and why the admin sees them

The broker refuses any host call the manifest did not declare, and the
limits (fuel, time, memory, bytes fetched) hold whatever the plugin does.
So the list in `manifest.toml` is a promise the server keeps for you.
Ask for the least you need: operators read it, and the marketplace shows
it before anything is installed.

## 6. Publish

Rename the crate and the manifest (`name` — lowercase, digits, dashes),
write a one-line `description`, and follow
[docs/PUBLISHING.md](https://github.com/vyasa-cms/vyasa/blob/main/docs/PUBLISHING.md):
your public key goes in the listing as `author_key`, the maintainers sign
the package with the marketplace key, and every Vyasa install can then
find it under Plugins → Browse plugins.

## Checks

The GitHub workflow builds the component and packs it with a throwaway
key on every push, with the same checks the server runs at install
(`vyasa` 0.1.0 or later).

## Licence

MIT or Apache-2.0, at your option. Your plugin can use any licence you like.
