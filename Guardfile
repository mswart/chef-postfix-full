guard 'rspec', :cli => "--tty"  do
  watch(%r{^spec/(.+)_spec\.rb$})                     { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^attributes/(.+)\.rb$})                    { |m| "spec" }
  watch(%r{^recipes/(.+)\.rb$})                       { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^libraries/(.+)\.rb$})                     { |m| "spec" }
end

# load Guardfile.local
local_guardfile = File.dirname(__FILE__) + "/Guardfile.local"
if File.file?(local_guardfile)
  self.instance_eval(Bundler.read_file(local_guardfile))
end
