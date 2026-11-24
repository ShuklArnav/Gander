# Gander

Gander is a small CLI library for the [Goose](https://github.com/aardappel/goose)
programming language. It builds a command tree from Goose enums and dispatches
matching `exec` overloads for the root command and selected subcommands.
See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## Features

- Define commands and nested subcommands with enum variants and fields.
- Attach immutable option metadata to commands.
- Add short descriptions, long descriptions, and nested help output.
- Dispatch through typed `exec` overloads.
- Reuse fixed option-array types for enums.
- Type aliases available for 5, 10, 15, or 20 option arrays.

## Requirements

Gander uses compile-time reflection features from a separate Goose compiler
build rather than the mainstream compiler branch. In particular, this build
supports two or three bindings for `fields<T>`:

```goose
const for <NAME, ACCESSOR> in fields<MyStruct> {}
const for <NAME, ACCESSOR, TYPE> in fields<MyStruct> {}
```

The third binding is the field's expression type (read-type in this release).
It also works for enum variant fields.

## Quick start

Create a Goose program that imports Gander, describes the command tree
with enums, and defines an overload for every value that should execute:

```goose
import gander from "..";

enum CLI {
    hello {
        shortdesc: const u8[:] = "Print a greeting",
        desc:      const u8[:] = "",
    },
}

fn exec(_: CLI) {}
fn exec(_: CLI.hello) {
    print("Hello!");
}

fn main() {
    let cli .= gander::CLI<CLI>("my-tool", "An example Gander CLI");
    let args = ["my-tool", "hello"];
    cli.run<CLI>(args);
}
```

`exec(rootEnumValue)` runs first. Dispatch then calls the overload for each
selected subcommand in argument order.

> **Callback requirement:** Because Goose reflection support is limited,
> Gander requires callback `exec` overloads to be defined for each command and
> subcommand. If a command callback is omitted, the first defined subcommand
> callback may be called as its fallback, so the subcommand runs twice. If a
> subcommand callback is omitted, the parent command callback is called in its
> place. Do not rely on these fallback behaviors.

## Command model

The top-level enum supplies the root command. Each variant becomes a
subcommand name.

```goose
enum CLI {
    serve {
        shortdesc: const u8[:] = "Start the server",
        desc:      const u8[:] = "Start the development server",
        commands:  ServerCommands,
        options:   Option[1] = [
            Option { "port", "Listen on this port" },
        ],
    },
}

enum ServerCommands {
    start {
        shortdesc: const u8[:] = "Start",
        desc:      const u8[:] = "",
    },
    stop {
        shortdesc: const u8[:] = "Stop",
        desc:      const u8[:] = "",
    },
}
```

- `shortdesc` and `desc` control command help text.
- `commands` names a nested enum type.
- `options` accepts a Gander fixed option-array alias.
- Variant names become command names without additional conversion.

Gander reexports these option-array aliases:

| Alias            | Capacity |
| ---------------- | -------: |
| `FiveOptions`    |        5 |
| `TenOptions`     |       10 |
| `FifteenOptions` |       15 |
| `TwentyOptions`  |       20 |

Options are currently represented as command metadata. Gander does not yet
parse option values or flags.

## Running the example

```powershell
goose check test/test.goose
goose test/test.goose
goose test/test.goose --debug
```

The example runs a fixed argument sequence and prints each selected `exec`
overload. It also demonstrates a nested command:

```text
Running `goose`
Running `goose command1`
Running `goose command1 subcommand2`
```

With `--help` or `-h` passed in a supported position, Gander prints the
current command tree:

```powershell
goose test/test.goose
```

## Project layout

```text
gander.goose       Public package entry point
src/init.goose     Namespace bootstrap and public reexports
src/cli.goose      Command construction and dispatch implementation
test/test.goose    Focused integration example
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Changes to `src/cli.goose` should be
typechecked and executed against `test/test.goose`.

## License

Gander is available under the [Apache License 2.0](LICENSE).