import argparse
import json
import os
import sys

sys.path.insert(0, os.getcwd())

SWITCHES = (
    argparse._StoreTrueAction,
    argparse._StoreFalseAction,
    argparse._StoreConstAction,
    argparse._VersionAction,
)


def subparser_of(parser):
    for action in parser._actions:
        if isinstance(action, argparse._SubParsersAction):
            return action
    return None


def flags_of(parser):
    out = {}
    for action in parser._actions:
        if not action.option_strings:
            continue
        if isinstance(action, argparse._SubParsersAction):
            continue
        entry = {}
        if action.help and action.help is not argparse.SUPPRESS:
            entry["description"] = action.help
        if not isinstance(action, SWITCHES):
            entry["nargs"] = 1
        for option in action.option_strings:
            out[option] = dict(entry)
    return out


def completions_of(parser):
    out = {}
    for action in parser._actions:
        if not action.option_strings:
            continue
        choices = getattr(action, "choices", None)
        if not choices:
            continue
        values = [str(choice) for choice in choices]
        for option in action.option_strings:
            out[option] = values
    return out


def build(parser, name, description):
    record = {"name": name, "description": description, "flags": flags_of(parser), "commands": []}
    completions = completions_of(parser)
    if completions:
        record["completion"] = {"flag": completions}
    subparsers = subparser_of(parser)
    if subparsers is not None:
        help_by_name = {choice.dest: (choice.help or "") for choice in subparsers._choices_actions}
        record["commands"] = [
            build(subparsers.choices[n], n, help_by_name.get(n, "")) for n in subparsers.choices
        ]
    return record


def root_parser(factory):
    result = factory()
    if isinstance(result, tuple):
        parsers = [x for x in result if isinstance(x, argparse.ArgumentParser)]
        if not parsers:
            raise SystemExit("factory returned a tuple without an ArgumentParser")
        return parsers[0]
    return result


def main():
    if len(sys.argv) != 2 or ":" not in sys.argv[1] or "=" not in sys.argv[1]:
        raise SystemExit("usage: argparse_spec.py <module>:<factory>=<name>")
    target, _, name = sys.argv[1].partition("=")
    module_name, _, factory_name = target.partition(":")
    module = __import__(module_name, fromlist=[factory_name])
    parser = root_parser(getattr(module, factory_name))
    sys.stdout.write(json.dumps(build(parser, name, "") or {}))


main()
