# Part 1 – Can AI Help Me Write a Commodore 64 Game?
## Nostalgia as a Starting Point

Some computers never really let go of you. For me, that is without a doubt the Commodore 64. Not because I owned one myself — quite the opposite — but more because I didn’t. As a child, I was deeply impressed by games. The sound, the sprites, the atmosphere. While many classmates had a C64 at home, I grew up with an MSX. Also a beautiful system, but different. Fewer games, less mystique. So I spent a lot of time at friends’ houses, staring at that iconic blue startup screen and waiting endlessly for a game to load from cassette.

The home computer — and especially the C64 — felt like magic. Games that were bigger, smoother, and more impressive than anything I knew. Games appeared that made us think: it will never get more beautiful or realistic than this.

## Programming… As Far as I Got

Like many others, I once started programming in BASIC. PRINT statements, GOTOs, simple loops. Fun and educational — but I never moved beyond the basics. The truly interesting things — fast games, demos with music and scrolling text — those were written in machine code. And machine code was intimidating. I read things about registers, 
memory addresses and hexadecimal values. It felt like a different world. A world I never truly entered. BASIC was safe. Machine code was for “real programmers”. And then life moved on. Studies, work, cloud, DevOps, C#, infrastructure as code. The C64 faded into the background as pure nostalgia. Until now , specialy the [re-release of the C64](https://www.commodore.net/product-page/commodore-64-ultimate-basic-beige-batch2) sparked my intrest again. 

## The Question That Lingered

*What if I tried again — now?* Not as a child with a manual and infinite patience, but as an experienced software engineer — with a new tool: AI. The question I asked myself was surprisingly simple:

> Would AI allow me to write something in machine code for the Commodore 64 — without really understanding that machine code myself?

I do not understand C64 assembly. Not really. And for this experiment, that was intentional. I wanted to experience what it’s like to vibe code at a very low level — to steer, prompt, and iterate without fully grasping every instruction or hardware detail. To see whether intent, feedback, and iteration could substitute for deep domain knowledge. I'm not trying to build a new masterpiece next-level game, but just something that runs. But just something built by AI — even if I couldn’t fully explain every byte of it.

### Constraints of the Experiment

To keep myself honest, I added two deliberate constraints.

1. **A strict time box**

I gave myself one month. If it took longer than that, I knew exactly what would happen:
I’d simply start learning C64 assembly properly — reading manuals, studying opcodes, and going deep.
That would be interesting, but it would defeat the purpose of the experiment. This wasn’t about learning assembly.
This was about discovering how far AI could take me without that learning.

2. **Gradually “smarter” models and adding more context**

I also decided not to start with specialized tools. The plan was simple: Start with default, generic AI models
See how far I could get and only escalate when it got stuck. First by add more context and eventualy if needed, I would move toward models more tailored to software development and code generation — things like OpenCode, Claude Code or OpenAI Codex CLI-style models — but only as a next step, not a given.

3. **Asking increasingly more difficuly questions.**

So starting with a simple "hello world" scroller is just the beginning. If this is succesful then i'll figure out some fancier request. 

## Naive Optimism: “Just Do a Hello World”
As often happens in modern software development, I started out quite naively. My first prompt was essentially:

> *“Write a Hello World scroller in C64 machine code.”*

And that’s where reality kicked in. Although an generic modelc like ChatGPT is able to create some code, i needed to figure out how and where to run this code. I was not going for typing it in a c64. I needed some sort of development environment. So I didn’t get stuck on the code itself, but I got stuck immediately on the tooling.

## Tooling: Where Do You Even Start?

In the 1980s, people programmed directly on the machine itself. Today we use cross-development tooling, which makes things considerably easier than they were back then. So i asked chatGPT the following:

> *"When developing a C64 machine code application on a Windows machine what is the best development stack?"*

After some fiddeling and experimenting with options mentioned in the result , I roughly ended up with the following stack:

- Kick Assembler – a modern assembler for 6502/6510 code
https://theweb.dk/KickAssembler/Main.html#frontpage

- Visual Studio Code – for editing, syntax highlighting, and structure

- Kick Assembler Studio – a VS Code plugin for C64 development
https://marketplace.visualstudio.com/items?itemName=sanmont.kickass-studio

- VICE – an emulator to actually run the code
https://vice-emu.sourceforge.io/


To efficiently develop C64 code, I use Kick Assembler together with the VICE emulator, controlled from Visual Studio Code. In practice, this means that Kick Assembler compiles your .asm file into a .prg file. VS Code invokes the assembler via a simple build task and eventualy VICE is launched automatically with the generated .prg. After setting up the tooling, I could press F5 to compile and immediately run the result in the VICE emulator. It almost feels like modern software development — except it’s targeting an 8-bit machine from 1982.

## Then Came the AI

So at this point i had a working tooling pipeline which supposably should be able to build and run generated C64 code. So back to the earlier generated code. After a few times going back and forth i has some code which compiled and the C64 emulator would start. Then i would load and it ended with a "Ready" prompt.. Nothing happing.. I tried to do an Run command.. but nothing happend. I thought that i need to supply more context to the AI and this turned out to be crucial.

Once I started feeding the AI proper reference material, things changed. In particular:

- **Commodore 64 Programmer’s Reference Guide**
- **KickAssembler Manual**

Especially the Commodore 64 Programmer’s Reference Guide — a book many people forgot in a desk drawer decades ago — had a noticeable impact on the quality and correctness of the generated code.

The ending up with a "READY" prompt problem appeared to some standard issue which kickassembler has an solution for. So i finally saw something appearing on the screen. But is was not "Hello World" as i expected but it was gibberish. I went back and forth a couple of times but didn't help. So i couldn't help myself and checkout the code. Although i don't understand the assembly part i did see the printed string was in all CAPS. The C64 didn't have ASCII as all machine have since the late 80's but it had PETSCII which was something different. So when i asked chatGpt about this i changed the code to lowercase.

At this point things started to work. The result of which a you can find in the github.com/pabes74/c64AI repo. The hello.asm should build and display is "hello world" scroller. So even without understanding C64 assembly, I could still make something real.

## The Road Ahead: Can We Actually Build a Game?

With a simple "Hello World" finally flickering on the screen, the proof of concept is done. I've proven that with the right tooling and enough context, I can coax an AI into writing 6502 assembly that actually *works*. But let’s be honest: printing a text string is a long way from a playable game.

The real experiment starts now. I’ve set my stopwatch for **one month**, and the goal is to see just how deep the rabbit hole goes. Here is what’s on the horizon for Part 2:

### Pushing the Models to the Limit
So far, I’ve been using generic AI models. They’re great for "Hello World," but will they crumble when asked to manage memory registers or timing-sensitive interrupts? I want to see exactly where "vibe coding" hits a brick wall. Will I need to call in the "heavy hitters" like specialized coding models, or can I "prompt engineer" my way through the limitations of a general-purpose LLM?

### The fantastic four of C64 Coding
To make this look like a real game, I need to tackle the classics that defined the era:
*   **Sprites:** Moving objects that don't mess up the background. The signature magic of the VIC-II chip.
*   **Smooth Scrolling:** No more static screens. I want that buttery-smooth 8-bit motion.
*   **The Game Loop:** Choreographing inputs, logic, and rendering without the whole thing crashing into a pile of assembly errors.
*   **Music:** The c64 contained the legendary SID chipset which generated great music, will AI be able to generate a tune?

### The "Vibe Coding" Reality Check
The biggest question remains: **where does it break?** At some point, the lack of deep domain knowledge *must* become a liability. I’m looking for that tipping point where the AI gives me code that looks "technically correct" but is fundamentally broken for a machine with only 64KB of RAM.

The journey from a "READY" prompt to a moving character is going to be full of PETSCII gibberish, memory collisions, and probably a lot of trial and error. I forsee a future where i did create a lot of stuff, which doesn't work as intended but i'm unable to fix this because i don't understand the basics.

**Stay tuned for Part 2 – where we find out if AI can actually play with the legends of the 80's.**

To be continued.
