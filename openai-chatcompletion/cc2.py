import sys, openai
print("openai", openai.__version__)
def run(name, fn):
    try: r = fn(); print(f"{name}: OK {r!r}"[:200])
    except Exception as e: print(f"{name}: {type(e).__name__}: {str(e).strip().splitlines()[0][:200]}")
run("from openai import ChatCompletion", lambda: __import__("openai", fromlist=["ChatCompletion"]).ChatCompletion)
run("type(openai.ChatCompletion)", lambda: type(openai.ChatCompletion).__name__)
run("openai.ChatCompletion()", lambda: openai.ChatCompletion())
run("openai.chatcompletion (lowercase)", lambda: openai.chatcompletion)
run("openai.Image.create", lambda: openai.Image.create(prompt="x"))
run("openai.Moderation.create", lambda: openai.Moderation.create(input="x"))
run("openai.Model.list", lambda: openai.Model.list())
run("openai.api_base =", lambda: setattr(openai, "api_base", "x"))
