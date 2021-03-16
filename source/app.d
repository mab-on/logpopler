import std.stdio;
import std.regex;
import std.array;
import std.conv;
import std.getopt;

enum Mode : byte {
	NON_BLOCKING_NON_UNIQUE,
	NON_BLOCKING_UNIQUE,
	BLOCKING_UNIQUE
}

void main(string[] args)
{
	auto opts = Opts(args);

    Aggregator agg;
    agg.ByCapturingGroups = opts.By;

    Mode mode;
    if(opts.ShowCount && opts.Min == 0) {
    	mode = Mode.NON_BLOCKING_NON_UNIQUE;
    }
    else if( ! opts.ShowCount && opts.Min > 0) {
    	mode = Mode.NON_BLOCKING_UNIQUE;	
    }
    else {
    	mode = Mode.BLOCKING_UNIQUE;
    }

    string line;
    while ((line = stdin.readln()) !is null) {
        foreach(c; line.matchAll(opts.Regexp)) {
        	auto hit = agg.Add(c.array);

        	switch(mode) {
				case Mode.NON_BLOCKING_UNIQUE:
					if(hit.Count == opts.Min) {
						hit.Print(opts);
					}
					break;
        		
        		case Mode.NON_BLOCKING_NON_UNIQUE:
					hit.Print(opts);
					break;

				default: assert(true);
        	}
        }
    }

    if(mode == Mode.BLOCKING_UNIQUE) {
		agg.Print(opts);
	}
}

struct Hit {
	int Count;
	string[] Matches;

	void Print(Opts opts) {
		if(this.Count < opts.Min ) return;

		string[] output;
		
		if(opts.ShowCount) {
			output ~= this.Count.to!string;
		}

		if(opts.Select.length == 0) {
			foreach(s, submatch; this.Matches) {
				if(this.Matches.length > 1 && s == 0) {
					continue;
				}
				output ~= submatch;
    		}
		}
		else {
			foreach(g ; opts.Select) {
    			foreach(s, submatch; this.Matches) {
    				if(g == s) {
    					output ~= submatch;
    				}
	    		}	
    		}
		}
		output.join("\t").writeln();}
}

struct Aggregator {
	Hit[string] hMap;
	alias hMap this;

	int[] byCapturingGroups;
	Appender!(char[]) keyBuilder;

	@property int[] ByCapturingGroups(int[] groups) {
		this.keyBuilder.reserve(groups.length);
		return this.byCapturingGroups = groups; 
	}

	Hit Add(string[] match) {
		
		string key;
		if(this.byCapturingGroups.length) {
			foreach(by; this.byCapturingGroups) {
				if(by > match.length) {
					throw new Exception("invalid group aggregator");
				}
				this.keyBuilder.put(match[by]);
			}
			key = this.keyBuilder.toString();
			this.keyBuilder.clear();
		} else {
			key = match[0];
		}

		if(Hit* hit = key in this.hMap) {
			hit.Count++;
			return (*hit);
		}

		auto hit = Hit();
		hit.Count = 1;
		hit.Matches ~= match.array;
		this.hMap[key] = hit;			
		return hit;
	}

	void Print(Opts opts) {
		foreach(hit; this.hMap) {
	    	hit.Print(opts);
	    }
	}
}

struct Opts {
	GetoptResult r;
	alias r this;

	bool ShowCount;
	int[] Select;
	int[] By;
	int Min = 1;
	Regex!char Regexp;

	this(string[] args) {
		import core.stdc.stdlib : exit;
		import std.stdio;
		import std.format;

		try {
			this.r = getopt(
				args,
				"select", "Defines which of the Group(s) from the RegExp-matches will be printed to stdout.", &this.Select,
				"by", "Defines BY which Capturing group(s) the aggregation will happen.", &this.By,
				"min", "Output threshold - At least $min hits must be aggregated until it get printed to stdout.", &this.Min,
				"show-count", "Shows the hit count for each match as the first column of the output.", &this.ShowCount,
			);
		} catch(Exception e) {
			writeln("error: ", e.message());
			exit(1);
		}
		
		if(this.r.helpWanted) {
			defaultGetoptPrinter(
				format!(
					"usage: %s [ARGS] <RegExp> \n\n"~
					"A tiny log aggregation command-line tool.\n\n"~
					"[ARGS]:\n"
				)(args[0]),
				this.r.options
			);
			writeln;
			exit(0);
		}

		if(args.length <= 1) {
			writeln("error: Missing <RegExp>");
			exit(1);	
		}
		try {
			this.Regexp = regex(args[1]);

		} catch(RegexException e) {
			writeln("error: ", e.message());
			exit(1);
		}

		
	}
}