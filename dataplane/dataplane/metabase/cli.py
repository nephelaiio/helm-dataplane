#!/usr/bin/env python3
import typer

app = typer.Typer()

@app.command("init", help="initialize metabase deployment")
def init(user_first_name: str = typer.Argument("Metabase", envvar="DATAPLANE_METABASE_INIT_USER_FIRST_NAME"),
         user_last_name: str = typer.Argument("User", envvar="DATAPLANE_METABASE_INIT_USER_LAST_NAME"),
         user_email: str = typer.Argument(envvar="DATAPLANE_METABASE_INIT_USER_EMAIL"),
         site_name: str = typer.Argument("Dataplane", envvar="DATAPLANE_METABASE_INIT_SITE_NAME"),
         metabase_url: str = typer.Argument(envvar="DATAPLANE_METABASE_INIT_SITE_NAME")):
    print("init metabase")

    curl -X POST -H "Content-Type: application/json" -d '{ "token": "56dd2a37-8383-4d07-b634-10ce7afb4835", "user": {"first_name": "xyz", "last_name": "abc", "email": "xyabzc@gmail.com", "password": "xzy7030"},"prefs": {"allow_tracking": true, "site_name": "yyzz"}}' http://localhost:3000/api/setup
