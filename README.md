# zit

A toy implementation of [Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects) in zig.

## Available CLI commands:

```
zit <command>
```

- `init`: initializes the object store at `./zit/objects` 
- `hash-object <file-path>`: writes compress blob of file at `<file-path>` to object storage
