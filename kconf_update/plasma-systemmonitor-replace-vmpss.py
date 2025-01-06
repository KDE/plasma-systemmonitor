#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2024 Arjen Hiemstra <ahiemstra@heimr.nl>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

# Update table faces to replace vmPSS with memory.
# This technically runs for systemmonitorrc but we don't make any actual changes
# to that file, instead we operate on the page files.
import sys

import pathlib
import configparser
import os
import tempfile
import shutil

pages_dir = pathlib.Path.home() / ".local" / "share" / "plasma-systemmonitor/"

for page in pages_dir.glob("*.page"):
    output = []
    modified = False

    with open(page, "r+") as f:
        input = f.readlines()

        for line in input:
            output.append(line)

            if "=" not in line:
                continue

            key = line.split("=")[0]
            if key not in ["columnDisplay", "sortColumn", "sortedColumns"]:
                continue

            if "memory" in line:
                continue

            line = line.replace("vmPSS", "memory")
            output[-1] = line
            modified = True

    if modified:
        handle, path = tempfile.mkstemp()

        with os.fdopen(handle, "w") as f:
            f.writelines(output)

        shutil.move(path, page)
