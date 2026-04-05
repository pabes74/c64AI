# Part 2 – Can AI Help Me Write a Commodore 64 Game?
## Recap
In my previous post, I set out on a nostalgic experiment to see if modern generative AI could bridge the forty-year gap back to the 8-bit constraints of the Commodore 64. By tasking ChatGPT with generating 6502 Assembly and BASIC code, I explored whether an LLM could truly grasp the intricacies of hardware registers and memory mapping that defined retro development. While the AI proved surprisingly capable of providing a functional foundation, the journey revealed that the "soul" of C64 programming—debugging those era-specific quirks and optimizing for every single byte—still demands a heavy dose of human intuition and manual refinement. Now, it's time to take those lessons and see if we can push the hardware (and the AI) even further.

## The AI setup for this part
In the first blog post we created the basic scroller using a generic web-based AI, like ChatGPT, Gemini and Perplexity. I've tried all three and they all responded with similar results, sometimes needing some additional coaxing to produce running code. For the next steps I switched to a more context-aware approach and tried an approach where I use Copilot CLI, Codex CLI or OpenCode CLI, changing the model depending on the results (switching between e.g. GPT-5.3-Codex, Claude Sonnet 4.5, Claude Opus 4.6)

## Moving Beyond the Code: The "Fantastic Four"
In my first post, I teased the "Fantastic Four" of Commodore 64 development—the four technical pillars that separated a simple program from a true gaming experience. These aren't just features; they are the hurdles that every C64 programmer eventually has to clear. To kick off Chapter 2, we are diving straight into the first and most visually satisfying of the bunch: Sprites.

### Sprites 
#### Main character
Just having a simple scrolling "hello world" is very nice, but on to the next step. Because having some visual feedback of a sprite on the screen is very cool. If I'm going to convert my current project into a game I need a basic theme and gameplay loop. So for the theme I wanted to stay in the 80's vibe and went with a karate-based theme. Thinking of games like Bruce Lee, IK+, Fist II, Karateka and one of my favourites Usagi Yojimbo. So I wanted to have a main sprite of our main hero — some karate guy who definitely does NOT skip leg day.

This is where I directly ran into some issues. Having an AI prompt create a sprite directly in code with a prompt similar to something like this:
> "Create a couple of 3 color sprites of a cool Karate guy, in a white gi with a black belt doing a walking animation and a kick, a kneel and a jump animation"

The results were not great, to say the least — floppy legs, arms pointing in directions that would make a physiotherapist weep, and animations that looked more like a drunk octopus than a martial artist. I left one of these cursed abominations in the code for the next part if you're curious (you have been warned). But I wanted something better. So I switched to a special-purpose AI which can create nice 8/16-bit pixel art sprites.
https://www.pixellab.ai/account

After some fiddling I ended up with the following sprite.
[Show pixellab.png]

The whole sprite sheet can be found (here)[]. This guy might be small, but he is a mean karate expert with a black belt and the confidence of someone who just found a hidden 1-UP.
Now that I have this image there is still the issue of getting the sprite with the right colors into a piece of C64 assembly code.

To be totally honest, I went off the AI path here and used the following site:
https://www.spritemate.com/
Here I could load the sprite sheet and export the sprites as hex assembly code. Displaying the sprite on the screen wasn't a big step from here. I just asked the AI to display it right under the scrolling text.

#### Logo
Next up was displaying a logo of the game title. Easier said than done because I needed a title first. So I asked the AI to come up with a cool name for a C64 karate-based game built with AI (similar to Bruce Lee, Karateka and Fist II). After a brief moment of silicon contemplation, it came up with:
> Artificial Fist
Not exactly Rolling Thunder or Street Fighter... but honestly, in a world where the AI also drew a sprite with four left feet, "Artificial Fist" feels oddly fitting. It will do. Now I needed a cool logo, so I generated one with an AI image generator in max 3 colors and a small size, because the C64 has a maximum resolution of 320x200 (with 2 colors) or 160x200 (with 4 colors). Telling an image generator that you want output with a maximum of 3 colors seems surprisingly difficult — apparently AI image generators didn't get the memo about working within constraints. So I had to alter the image myself to 3 colors max.

[Display logo]

To get the bitmap I followed the same procedure as for the sprites, and getting it to display was an easy step from here.

### SID chip
It's arguably the most famous sound chip in history, capable of pulse-width modulation, ring modulation, and filtered sweeps that could fill a bedroom with the sonic equivalent of a blockbuster movie — all coming from a chip the size of your thumbnail. Back in the 80's the creators of these game tunes were like childhood heroes: names like Jeroen Tel, Rob Hubbard, Ben Daglish and Martin Galway were whispered in reverent tones across schoolyards everywhere. These guys could make or break a game. There were games that were only famous and popular for their music — yes, people bought games purely because Rob Hubbard wrote the soundtrack. Try explaining *that* to a modern game studio.

So anyway, I need some cool music as well. Getting something really cool generated by AI proved more difficult than expected. AI could generate some basic music, but nothing near the quality these legends produced. It turns out that 40 years of SID wizardry is not something a language model can just... vibe into existence.

So I made a decision to go the same route as with the sprite: have a dedicated music generator AI tool generate some SID-like chiptune music and use AI to try to convert it back to a SID or assembly file. For now I would just implement a placeholder using an existing SID tune from the 80's series Airwolf — because if you're going to steal, steal from the best.

### Lesson learned and beyond
All these things together result in the following title screen of Artificial Fist!
[Video of titlescreen]
Having custom AI tools for custom jobs is advised for different tasks. In most cases you can use the output of one tool as input for another tool — it's like a very nerdy assembly line where each robot speaks a slightly different language but somehow the car still gets built. Understanding the generated code base keeps getting increasingly difficult, but we haven't gotten to the real hard parts yet. In the next part, some real game logic should be implemented with a scrolling background and animated sprites. 

Fair warning: if the sprites in Part 3 still look like drunk octopuses, I'm blaming the AI.



