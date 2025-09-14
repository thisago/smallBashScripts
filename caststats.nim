#!/usr/bin/env -S nim r --hints:off
# -*- mode: nim -*-

# Script that raises some interesting stats from a asciicast.
# Unfortunately nimscript doesn't seems to support streams
# So the file is named ".nim" for the Nim compiler to work

import std/[os, streams, json, tables, strutils]

type
  Event = tuple
    sec: float
    kind: string
    content: string
  Stats = object
    eventsCount: Table[string, int] # event kind/count
    lastSec: float
    plainTextStdin: string

proc extractEvents(strm: FileStream): seq[Event] =
  var line = strm.readLine
  while strm.readLine line:
    let event = line.parseJson
    result.add (
      sec: event[0].getFloat,
      kind: event[1].getStr,
      content: event[2].getStr,
    ).Event

const WritingChars = Letters + Digits + PunctuationChars + {' '}
proc generateStats(events: seq[Event]): Stats =
  for event in events:
    if not result.eventsCount.hasKey event.kind:
      result.eventsCount[event.kind] = 1
    else:
      inc result.eventsCount[event.kind]

    if event.kind == "i":
      if event.content.len > 2 or event.content[0] notin WritingChars:
        case event.content:
          of "\r", "\u001b":
            result.plainTextStdin.add "\l"
          of "\u0001":
            result.plainTextStdin = result.plainTextStdin[0..^2]
          else:
            discard
        continue
      result.plainTextStdin.add event.content
  result.lastSec = events[^1].sec

proc main(args: seq[string]): int =
  if args.len != 1:
    echo "Usage:"
    echo "  caststats [CAST FILE]"
    return 1

  let castFile = args[0]
  if castFile.len <= 0 or not castFile.fileExists:
    echo "Cast file doesn't exists"
    return 1

  var strm = castFile.newFileStream fmRead
  defer: strm.close()

  let
    events = strm.extractEvents
    stats = generateStats(events)

  echo %*stats

when isMainModule:
  quit main(commandLineParams())
