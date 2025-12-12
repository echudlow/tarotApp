import os
import re
from typing import List, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from openai import OpenAI


# ----------------- Setup -----------------
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise RuntimeError("OPENAI_API_KEY not set")

client = OpenAI(api_key=OPENAI_API_KEY)

app = FastAPI(title="Tarot AI Backend")


# ----------------- iOS Models -----------------
class TarotCardInput(BaseModel):
    name: str
    suit: Optional[str] = None
    number: Optional[int] = None
    position: str
    is_reversed: bool
    upright_meaning: str
    reversed_meaning: str
    keywords: Optional[str] = None
    imageName: Optional[str] = None
    arcana: Optional[str] = None


class SpreadRequest(BaseModel):
    spread_type: str
    cards: List[TarotCardInput]


class SpreadResponse(BaseModel):
    interpretation: str


# ----------------- Prompt building -----------------
def build_prompt(req: SpreadRequest) -> str:
    n = len(req.cards)
    is_daily = (req.spread_type == "daily") or (n == 1)

    if is_daily:
        c = req.cards[0]
        orientation = "Reversed" if c.is_reversed else "Upright"
        meaning = c.reversed_meaning if c.is_reversed else c.upright_meaning

        return f"""
You are a tarot reader. Write an interpretation for a SINGLE CARD daily draw.

STRICT RULES:
- Do NOT use Past/Present/Future.
- Do NOT include greetings or filler like "Certainly!", "Sure!", "Of course!".
- Do NOT mention that you're an AI.
- Output ONLY in this exact structure:

**Daily Card — {c.name} ({orientation}):**
<1–2 short paragraphs>

**Overall Message:**
<1 short paragraph>

Card meaning reference (use as guidance, do not quote verbatim):
{meaning}
""".strip()

    lines = [
        "You are a tarot reader. Interpret the following spread.",
        "",
        "STRICT RULES:",
        "- Do NOT include greetings or filler like \"Certainly!\", \"Sure!\", \"Of course!\".",
        "- For EACH card, output exactly one section in this format:",
        "  **<Position> — <Card Name> (<Upright/Reversed>):**",
        "  <1 paragraph interpretation>",
        "- End with:",
        "  **Putting It All Together:**",
        "  <1 paragraph synthesis>",
        "",
        "CARDS:",
    ]

    for c in req.cards:
        orientation = "Reversed" if c.is_reversed else "Upright"
        meaning = c.reversed_meaning if c.is_reversed else c.upright_meaning
        lines.append(
            f"- Position: {c.position} | Card: {c.name} | Orientation: {orientation} | MeaningRef: {meaning}"
        )

    return "\n".join(lines)


# ----------------- Output normalization (guardrail) -----------------
def normalize_output(req: SpreadRequest, text: str) -> str:
    n = len(req.cards)
    is_daily = (req.spread_type == "daily") or (n == 1)

    # strip common "cheerful" openers
    text = re.sub(
        r"^\s*(Certainly!|Sure!|Of course!|Absolutely!|Okay!|Alright!)[^\n]*\n+",
        "",
        text,
        flags=re.IGNORECASE,
    ).strip()

    if is_daily:
        # If the model still tried to do Past/Present/Future, strip those headings.
        # (We keep the remaining paragraphs so you still get *something*.)
        text = re.sub(
            r"\*\*\s*(Past|Present|Future)\s*—.*?\*\*:?(\s*)",
            "",
            text,
            flags=re.IGNORECASE,
        ).strip()

        # If the model forgot the Daily Card header, prepend a simple one.
        if "**Daily Card" not in text:
            c = req.cards[0]
            orientation = "Reversed" if c.is_reversed else "Upright"
            text = f"**Daily Card — {c.name} ({orientation}):**\n{text}".strip()

    return text.strip()


# ----------------- Route -----------------
@app.post("/interpret_spread", response_model=SpreadResponse)
def interpret_spread(req: SpreadRequest):
    if not req.cards:
        raise HTTPException(status_code=400, detail="No cards provided")

    prompt = build_prompt(req)

    # Helpful for debugging to confirm you received the right payload:
    # print("spread_type:", req.spread_type, "n_cards:", len(req.cards), "positions:", [c.position for c in req.cards])

    try:
        completion = client.responses.create(
            model="gpt-4.1-mini",
            input=(
                "You are a tarot reader. Be warm, clear, and realistic. "
                "Follow the user-provided STRICT RULES exactly.\n\n"
                f"{prompt}"
            ),
            max_output_tokens=700,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OpenAI request failed: {e}")

    # Responses API format: text lives in output[0].content[...].text
    text_parts: List[str] = []
    if completion.output:
        for item in completion.output:
            if getattr(item, "type", None) == "message":
                for part in getattr(item, "content", []) or []:
                    t = getattr(part, "text", None)
                    if t:
                        text_parts.append(t)

    text = "".join(text_parts).strip()
    if not text:
        text = "I'm sorry, I couldn't interpret this spread right now."

    text = normalize_output(req, text)

    return SpreadResponse(interpretation=text)
