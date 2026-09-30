import argparse


def factory():
    parser = argparse.ArgumentParser(prog="toolx", description="A test tool")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--mode", choices=["fast", "slow", "auto"], help="Run mode")
    subparsers = parser.add_subparsers(dest="cmd", metavar="COMMAND")
    run = subparsers.add_parser("run", help="Run the thing")
    run.add_argument("--jobs", "-j", help="Job count")
    nested = run.add_subparsers(dest="sub", metavar="COMMAND")
    nested.add_parser("now", help="Run now")
    return parser
