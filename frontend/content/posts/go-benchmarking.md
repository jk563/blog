+++
title = 'Go Benchmarking'
date = 2023-06-13T16:19:02+01:00
tags = ['golang', 'benchmarking']
[params]
    description = "How to create benchmarking tests in go, run them, and compare results"
+++

Go provides benchmarking features in the [testing](https://pkg.go.dev/testing#hdr-Benchmarks") package which you can use to measure the performance of your code. There are also tools available to interpret the results of these tests, such as [benchstat](https://pkg.go.dev/golang.org/x/perf/cmd/benchstat) for summarising and comparing benchmarks, which we'll take a look at too.

## Why Benchmark?
Benchmarking can be used to test for performance changes in a key section of your code, or for comparing performance of different implementations. Whilst you are, of course, free to implement benchmarking tests for as much of your codebase as you like; I'd recommend only writing benchmark tests for performance sensitive sections of your codebase, or to cover a known bottleneck that you want to improve. This recommendation is down to the amount of time taken to run these tests — instrumenting benchmark tests for every function you write will soon leave you with a very long running benchmarking suite for very little value! A well selected small suite of benchmark tests will result in a quick running, high value report of key areas of performance.

## Writing and Running a Benchmark Test in Go
To run a benchmarking suite, you pass the `-bench` argument to the `go test` command. Go will then automatically run tests that match the benchmarking function form:

```
func BenchmarkXxx(*testing.B)
```

The structure of a typical benchmarking test will execute a section of code _n_ times, where _n_ is a big enough number that a reliable runtime can be established. The `testing.B` struct includes a field `N` to represent this number of iterations to establish a benchmark. Go will automatically adjust `N` to a suitable value during test execution for you. Super handy.

This snippet will run a benchmark test against `MyFunction`:

```
func BenchmarkMyFunction(b *testing.B) {
    for i := 0; i < b.N; i++ {
        MyFunction()
    }
}
```

When running the benchmark, Go will run `MyFunction` up to `N` times per benchmark, as we talked about previously, Go will figure out how high N will be for you. Running this locally gives us some handy output:

```
$ go test -bench .
goos: darwin
goarch: arm64
pkg: jamiekelly.com/fizzbuzz/v2
BenchmarkMyFunction-8            2858847               402.3 ns/op
PASS
ok      jamiekelly.com/fizzbuzz/v2      1.759s
```

What we can see with these results is that our test `BenchmarkMyFunction` was tested _2858847_ times (our `N` with an average runtime of _402.3ns_.

## Benchmarking for Comparison
To gather statistically significant output that we can use for comparison, Go recommends that you run the benchmarking test at least 10 times. We'll do this now with my existing implementation and save the output to a file.

```
$ go test -bench . -count 10 > bench1.txt
```

## Comparing Implementations
In order to compare different implementations, I'm going to do some magic optimisations to `MyFunction` and run the benchmark again, this time outputting to a new file.

```
$ go test -bench . -count 10 > bench2.txt
```

So we now have _bench1.txt_ and _bench2.txt_ with our before and after benchmarking results. Having these files is all well and good, but not exactly easy to compare across. Thankfully Go has a `benchstat` command in the `perf` module which can compare these files for us. Running `benchstat` with our two files gives us some much nicer output:

```
$ benchstat bench1.txt bench2.txt
goos: darwin
goarch: arm64
pkg: jamiekelly.com/fizzbuzz/v2
         │ bench1.txt  │             bench2.txt              │
         │   sec/op    │   sec/op     vs base                │
MyFunction-8   403.1n ± 1%   203.1n ± 1%  -49.62% (p=0.000 n=10)
```

`benchstat` has pulled in the results of both of our test runs and given us their averages along with summary stats: our optimisations reduced function runtime by 49.62%! It can compare results across an arbitrary number of benchmark runs and individual tests.<

## Summary
We've seen how to create benchmark tests and how to compare results of individual benchmarking runs  with each other. There's plenty more to explore when it comes to benchmarking, such as [subbenchmarking](https://pkg.go.dev/testing#B.Run) and using [custom timing](https://pkg.go.dev/testing#B.ResetTimer) among others. Try them out and have a think about where you could benefit from benchmarking.

