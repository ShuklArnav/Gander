import gander from "..";

enum CLI {
    command1 {
        shortdesc: const u8[:] = "",
        desc:      const u8[:] = "",
        commands:  Command1,
        options:   FiveOptions = [gander::Option { "Some", "" }],
    },
    command2 {
        shortdesc: const u8[:] = "",
        desc:      const u8[:] = "",
    },
}

enum Command1 {
    subcommand1 {
        shortdesc: const u8[:] = "",
        desc:      const u8[:] = "",
    },
    subcommand2 {
        shortdesc: const u8[:] = "",
        desc:      const u8[:] = "",
    },
}

fn exec(_: CLI) { print("Running `goose`") }
fn exec(_: CLI.command1) { print("Running `goose command1`") }
fn exec(_: Command1.subcommand1) { print("Running `goose command1 subcommand1`") }
fn exec(_: Command1.subcommand2) { print("Running `goose command1 subcommand2`") }
fn exec(_: CLI.command2) { print("Running `goose command2`") }

fn main() {
    let cli .= gander::CLI<CLI>("goose", "The Goose runtime");
    let args = ["goose", "command1", "subcommand2"];
    cli.run<CLI>(args);
    // Expected output:
    // Running `goose`
    // Running `goose command1`
    // Running `goose command1 subcommand2`
}
