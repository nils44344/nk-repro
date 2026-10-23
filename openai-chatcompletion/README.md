# module 'openai' has no attribute 'ChatCompletion'

Python 3.14.5, Windows 11, October 23, 2026. One venv per version: openai 0.26.5, 0.28.1, 1.40.0, 1.55.3, 3.37.0.

- `cc.py`: old (`openai.ChatCompletion.create`, `openai.Completion`, `openai.Embedding`, `openai.error`) and new calls against a local server that records requests.
- `cc2.py`: which old names raise `APIRemovedInV1` and which raise `AttributeError`.
- `cc3.py`: `openai.api_base` is silently ignored on 1.x and later; `openai.base_url` works.
- Shadowing: a file named `openai.py` next to the script gives the same `AttributeError` on any version.

    python -I cc.py
