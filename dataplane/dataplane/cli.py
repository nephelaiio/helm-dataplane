#!/usr/bin/env python3
import typer
import dataplane.metabase

app = typer.Typer()
app.add_typer(dataplane.metabase.app,
              name="metabase",
              help="metabase configuration subcommands")

def main():
    app()

if __name__ == "__main__":
    main()
