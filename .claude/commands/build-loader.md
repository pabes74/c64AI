Build the loader.asm KickAssembler project and check for errors.

Run the following command from the repo root:

```bash
java -jar /home/pabes/Projects/kickassembler/KickAss.jar -odir ./bin -log buildlog.txt -showmem -debugdump -vicesymbols loader.asm
```

Then read `buildlog.txt` and report:
1. Whether the build succeeded (no `Error` lines)
2. Any errors or warnings found
3. The memory layout summary if the build succeeded
