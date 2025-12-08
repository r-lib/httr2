# `StreamingBody` class

`StreamingBody` class

`StreamingBody` class

## Details

This R6 class is used to represent the body of a streaming response.
When using this in mocked responses, you can either create a new
instance using your own connection or use a subclass for some other
representation. In either case, you will pass to the `body` argument of
[`new_response()`](https://httr2.r-lib.org/reference/new_response.md).

## Methods

### Public methods

- [`StreamingBody$new()`](#method-StreamingBody-new)

- [`StreamingBody$read()`](#method-StreamingBody-read)

- [`StreamingBody$read_all()`](#method-StreamingBody-read_all)

- [`StreamingBody$is_open()`](#method-StreamingBody-is_open)

- [`StreamingBody$is_complete()`](#method-StreamingBody-is_complete)

- [`StreamingBody$get_fdset()`](#method-StreamingBody-get_fdset)

- [`StreamingBody$close()`](#method-StreamingBody-close)

- [`StreamingBody$clone()`](#method-StreamingBody-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new object

#### Usage

    StreamingBody$new(conn)

#### Arguments

- `conn`:

  A connection, that is open and ready for reading. `StreamingBody` will
  take care of closing it.\`

------------------------------------------------------------------------

### Method `read()`

Read `n` bytes into a raw vector.

#### Usage

    StreamingBody$read(n)

#### Arguments

- `n`:

  Number of bytes to read

------------------------------------------------------------------------

### Method `read_all()`

Read all bytes and close the connection.

#### Usage

    StreamingBody$read_all(buffer = 32 * 1024)

#### Arguments

- `buffer`:

  Buffer size, in bytes.

------------------------------------------------------------------------

### Method `is_open()`

Is the connection still open?

#### Usage

    StreamingBody$is_open()

------------------------------------------------------------------------

### Method `is_complete()`

Is the connection complete? (i.e. is there data remaining to be read?)

#### Usage

    StreamingBody$is_complete()

------------------------------------------------------------------------

### Method `get_fdset()`

Get the active file descriptions and timeout from the handle. Wrapper
around
[`curl::multi_fdset()`](https://jeroen.r-universe.dev/curl/reference/multi.html).

#### Usage

    StreamingBody$get_fdset()

------------------------------------------------------------------------

### Method [`close()`](https://rdrr.io/r/base/connections.html)

Close the connection

#### Usage

    StreamingBody$close()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    StreamingBody$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
