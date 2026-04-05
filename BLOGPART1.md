# Part 1: Can AI Help Me Write a Commodore 64 Game?

## Nostalgia as a Starting Point

Some computers never really let go of you. For me, that is without a doubt the Commodore 64. Not because I owned one myself—quite the opposite—but because I didn’t. 

As a child, I was captivated by the magic of 8-bit machines: the distinct SID chip synthesis, the hardware sprites, and that unmistakable atmosphere. While my classmates were loading games on their C64s, I grew up with an MSX. It was a beautiful system, but it felt different—less "mystique," fewer games. I spent countless hours at friends' houses, staring at that iconic blue startup screen, waiting with bated breath for a cassette tape to load.

The C64 felt like high technology. It was a machine where games felt bigger, smoother, and more "professional" than anything else. Back then, we truly believed it would never get more realistic than this.

## Programming… As Far as I Got

Like many kids of that era, I dabbled in BASIC. `PRINT` statements, `GOTO` commands, and simple loops were my playground. It was fun, but I never peaked over the wall. The truly legendary stuff—the high-speed games, the "cracktro" demos with scrolling text and complex music—was written in machine code.

To a kid, machine code was intimidating. I saw snippets of code filled with registers, memory addresses, and hexadecimal values (like `$FF`). It felt like a different dimension. BASIC was safe; machine code was for "real programmers." 

Eventually, life moved on. I became a "real programmer," but in a world of C#, DevOps, Cloud infrastructure, and Kubernetes. The C64 faded into a nostalgic memory—until the [re-release of the C64](https://www.commodore.net/product-page/commodore-64-ultimate-basic-beige-batch2) sparked my interest again.

## The Question That Lingered

*What if I tried again—now?* I’m no longer a child with just a manual and infinite patience. I’m an experienced software engineer with a powerful new ally: AI. I asked myself a simple, perhaps naive, question:

> **Can AI allow me to write machine code for the Commodore 64 without me actually understanding that machine code?**

I wanted to "vibe code" at the lowest possible level. I wanted to see if intent, feedback, and iteration could substitute for deep domain knowledge. I wasn't looking to build a masterpiece—just something that *runs*. Something built by an LLM, even if I couldn’t fully explain every byte it generated.

### Constraints of the Experiment

To keep myself honest, I set three rules:

1. **A Strict Time Box:** I gave myself one month. Any longer and I’d inevitably start "cheating" by actually learning 6502 assembly properly. This experiment is about the AI, not my ability to study opcodes.
2. **Gradual "Intelligence" Scaling:** I started with generic, out-of-the-box AI models. I would only move to "heavy hitters" (like specialized coding models or Claude Code) if the basic models hit a hard ceiling.
3. **Increasing Difficulty:** We start with "Hello World." If that works, we keep pushing until the machine (or the AI) breaks.

---

## Naive Optimism: “Just Do a Hello World”

In modern development, we’re spoiled. My first prompt was essentially: 
> *“Write a Hello World scroller in C64 machine code.”*

Reality hit immediately. While ChatGPT could spit out assembly code, I had no idea how to actually *run* it. I wasn't about to type hexadecimal values into a physical C64. I needed a modern dev-stack for a 40-year-old computer.

## Tooling: Where Do You Even Start?

In the '80s, you programmed on the metal. Today, we use **cross-development**. After some trial and error, I landed on a stack that makes 8-bit coding feel surprisingly like my day job:

| Tool | Purpose |
| :--- | :--- |
| [**Kick Assembler**](https://theweb.dk/KickAssembler/Main.html#frontpage) | A powerful, modern Java-based assembler for 6502/6510 code. |
| **VS Code** | My familiar editor for syntax highlighting and structure. |
| [**KickAssembler Studio**](https://marketplace.visualstudio.com/items?itemName=sanmont.kickass-studio) | A VS Code plugin that bridges the editor and the compiler. |
| [**VICE**](https://vice-emu.sourceforge.io/) | The gold-standard emulator to actually run the code. |



Setting this up was the first real hurdle. I had to configure VS Code tasks so that hitting **F5** would trigger Kick Assembler to compile my `.asm` into a `.prg` file and automatically launch VICE. It felt like modern CI/CD, only the target environment had 64KB of RAM instead of an Azure cluster.

## Then Came the AI

With the pipeline ready, I fed the AI-generated code into the assembler. It compiled! I launched the emulator... and was greeted with a blank blue screen and a "READY" prompt. Nothing happened.

This was a classic "gotcha" in the world of 8-bit development. On a Commodore 64, the machine starts in a BASIC environment, and machine code doesn’t just execute itself upon loading. You typically need a "BASIC stub"—a tiny line of BASIC code (like `10 SYS 2048`) that tells the processor to jump to the specific memory address where your machine code lives. KickAssembler has a standard, elegant solution for this using the `BasicUpstart2` macro. After feeding the AI more documentation, it correctly identified this requirement and added the necessary header, finally bridging the gap between the blue startup screen and my actual code.

I realized I was missing **context**. AI models know "code," but they don't necessarily know the quirks of the C64 hardware without help. I started feeding the AI reference material by uploading key documentation to the chat:
* **The C64 Programmer’s Reference Guide**
* **The KickAssembler Manual**

This was the turning point. By providing the "rules of the world," the AI's output improved drastically. However, we hit another problem. My "Hello World" appeared as weird symbols. As a C# dev, I take ASCII for granted. The C64 uses **PETSCII**. When I pointed this out to the AI, it corrected the string encoding to lowercase (which maps differently in PETSCII). 

Finally, it worked. A "Hello World" scroller, written in a language I don't speak, running on a machine from 1982. You can check out the "vibe-coded" source at [github.com/pabes74/c64AI](https://github.com/pabes74/c64AI).

---

## The Road Ahead: Can We Actually Build a Game?

The proof of concept is done. I’ve proven that with the right tooling and enough context, I can coax an AI into writing working 6502 assembly. But printing text is easy. A game is another beast entirely.

For **Part 2**, the goal is to see where "vibe coding" hits a brick wall. I'll be tackling the "Fantastic Four" of C64 coding:
* **Sprites:** Moving hardware objects without destroying the background.
* **Smooth Scrolling:** Achieving that buttery 8-bit motion.
* **The Game Loop:** Managing logic, input, and rendering simultaneously.
* **The SID Chip:** Can an AI actually compose a tune for the legendary sound chip?

The biggest question remains: **Where does it break?** At some point, the lack of deep domain knowledge *must* become a liability. I’m looking for that tipping point where the AI gives me code that looks "technically correct" but is fundamentally broken for a machine with only 64KB of RAM.

**Stay tuned for Part 2—where we find out if AI can truly play with the legends of the '80s.**