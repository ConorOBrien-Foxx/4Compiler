require_relative "src/4c/compilers.rb"

compiler = nil
options = {}
case ARGV[0].downcase
when "d", "dlang"
    compiler = FourToD
when "p", "pretty"
    compiler = FourPretifier
when "pv", "prettyverbose"
    compiler = FourPretifier
    options[:verbose] = true
else
    STDERR.puts "Invalid compiler target: #{ARGV[0]}"
    exit 2
end
a = compiler.new File.read(ARGV[1]), **options
puts a.compile