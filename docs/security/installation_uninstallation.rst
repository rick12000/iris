Installation and Uninstallation
################################

Installation
============

The application can either be built from source manually (as detailed in the README) or
by using the dedicated installer for your OS:

- Windows: `setup.ps1 <https://github.com/rick12000/vocalance/releases/latest/download/setup.ps1>`_
- macOS (Apple Silicon): `setup.sh <https://github.com/rick12000/vocalance/releases/latest/download/setup.sh>`_

Both scripts are bundled with each release. Below we detail the workflow.

Privilege model
---------------

In accordance with the principle of least privilege, the scripts run as the current user. No administrator or root privileges are
requested or required. The macOS installer aborts if it is run as root.

- Windows install root: ``%LOCALAPPDATA%\Programs\Vocalance\``
- macOS install root: ``~/Library/Application Support/Vocalance/runtime/``

Installation flow
-----------------

1. **Bootstrap uv** — downloads the official UV archive from GitHub releases for the pinned
   UV version and verifies its SHA-256 before extracting.

   - Windows: ``uv-{arch}-pc-windows-msvc.zip``, hash in ``$UV_ZIP_SHA256``.
     ``uv.exe`` is placed in ``%LOCALAPPDATA%\Programs\Vocalance\tools\uv.exe``.
   - macOS: ``uv-aarch64-apple-darwin.tar.gz``, hash in ``UV_ARCHIVE_SHA256``.
     ``uv`` is placed in ``~/Library/Application Support/Vocalance/runtime/tools/uv``.

   A mismatch deletes the archive and aborts. No system-wide UV installation occurs and ``PATH`` is not modified. See
   :ref:`security/supply_chain_integrity:UV Bootstrap` for the full verification
   procedure.

2. **Download Vocalance release** — fetches ``vocalance-v{VERSION}.zip``
   from the immutable GitHub releases page for the pinned version and unpacks it to
   ``app/`` under the install root.

3. **Create virtual environment** — ``uv venv --python 3.13.9``.

4. **Install dependencies** — prompts the user on whether to include LLM features,
   then runs ``uv sync --frozen`` if features are excluded and ``uv sync --frozen --extra llm`` otherwise.
   ``--frozen`` enforces ``uv.lock`` with per-package hash verification (see
   :ref:`security/supply_chain_integrity:Python Libraries`).

5. **Create launcher**

   - Windows: Start Menu shortcut to ``pythonw.exe vocalance.py``.
   - macOS: ``~/Applications/Vocalance.app`` launching the venv Python on ``vocalance.py``, with
     ``NSMicrophoneUsageDescription`` in ``Info.plist``. Grant Microphone and Accessibility
     in System Settings after first launch.

File layout
-----------

Windows
^^^^^^^

.. list-table::
   :widths: 45 55
   :header-rows: 1
   :class: uniform-rows

   * - Path
     - Contents
   * - ``%LOCALAPPDATA%\Programs\Vocalance\app\``
     - Source code, ``uv.lock``, bundled models, scripts.
   * - ``%LOCALAPPDATA%\Programs\Vocalance\env\``
     - Python virtual environment.
   * - ``%LOCALAPPDATA%\Programs\Vocalance\tools\uv.exe``
     - Bundled uv binary; scoped to this installation.
   * - ``%APPDATA%\Vocalance\``
     - All runtime-written data: configuration, marks, aliases, commands,
       activity logs, LLM model files, developer log files. Created by the
       application on first launch.

macOS
^^^^^

.. list-table::
   :widths: 45 55
   :header-rows: 1
   :class: uniform-rows

   * - Path
     - Contents
   * - ``~/Library/Application Support/Vocalance/runtime/app/``
     - Source code, ``uv.lock``, bundled models, scripts.
   * - ``~/Library/Application Support/Vocalance/runtime/env/``
     - Python virtual environment.
   * - ``~/Library/Application Support/Vocalance/runtime/tools/uv``
     - Bundled uv binary; scoped to this installation.
   * - ``~/Library/Application Support/Vocalance/``
     - User data (settings, marks, aliases, commands, logs, models) plus the
       ``runtime/`` install tree.
   * - ``~/Applications/Vocalance.app``
     - Launcher used so macOS privacy prompts attach to Vocalance rather than a bare Python process.


Uninstallation
==============

Uninstallation scripts are provided with each release:

- Windows: `cleanup.ps1 <https://github.com/rick12000/vocalance/releases/latest/download/cleanup.ps1>`_
- macOS: `cleanup.sh <https://github.com/rick12000/vocalance/releases/latest/download/cleanup.sh>`_

They run as the current user (no elevation) and remove:

Windows
^^^^^^^

1. ``%LOCALAPPDATA%\Programs\Vocalance\`` — source, virtual environment, bundled
   uv binary.
2. ``%APPDATA%\Vocalance\`` — all user-configured state.
3. The Start Menu shortcut.

macOS
^^^^^

1. ``~/Applications/Vocalance.app`` — launcher.
2. ``~/Library/Application Support/Vocalance/`` — user data and the runtime install tree.

After cleanup, no Vocalance files remain on the machine. Third-party package
caches (uv, PyPI) and system prerequisites installed independently by the user
(e.g. Microsoft C++ Build Tools, Xcode Command Line Tools) are not touched.
