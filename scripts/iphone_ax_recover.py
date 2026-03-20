#!/usr/bin/env python3
import argparse
import asyncio
import json
import sys

from pymobiledevice3.lockdown import create_using_usbmux
from pymobiledevice3.services.accessibilityaudit import AccessibilityAudit


async def list_elements(limit: int) -> int:
    lockdown = await create_using_usbmux()
    async with AccessibilityAudit(lockdown) as service:
        count = 0
        async for element in service.iter_elements():
            print(
                json.dumps(
                    {
                        "caption": element.caption,
                        "spoken_description": element.spoken_description,
                        "platform_identifier": element.platform_identifier,
                    },
                    ensure_ascii=False,
                )
            )
            count += 1
            if limit and count >= limit:
                break
    return 0


async def press_match(match: str, limit: int) -> int:
    lockdown = await create_using_usbmux()
    async with AccessibilityAudit(lockdown) as service:
        count = 0
        async for element in service.iter_elements():
            haystacks = [element.caption or "", element.spoken_description or "", element.platform_identifier or ""]
            if any(match.lower() in field.lower() for field in haystacks):
                await service.perform_press(element.element.identifier)
                print(
                    json.dumps(
                        {
                            "pressed": True,
                            "caption": element.caption,
                            "spoken_description": element.spoken_description,
                            "platform_identifier": element.platform_identifier,
                        },
                        ensure_ascii=False,
                    )
                )
                return 0
            count += 1
            if limit and count >= limit:
                break
    print(json.dumps({"pressed": False, "match": match}, ensure_ascii=False))
    return 1


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="cmd", required=True)

    list_parser = subparsers.add_parser("list")
    list_parser.add_argument("--limit", type=int, default=0)

    press_parser = subparsers.add_parser("press")
    press_parser.add_argument("match")
    press_parser.add_argument("--limit", type=int, default=0)

    args = parser.parse_args()
    if args.cmd == "list":
        return asyncio.run(list_elements(args.limit))
    if args.cmd == "press":
        return asyncio.run(press_match(args.match, args.limit))
    return 2


if __name__ == "__main__":
    sys.exit(main())

