This is a Ruby program that receives a path to dirname or filename and uploads the file or the files in the given directory (and all directories within) as a gist into GitHub.

Additionally, the script:
* Displays upload progress
* When upload finishes prints gist’s url
* If a connection error occurs, gives the user an option to resume.

Run instructions:
ruby lib/add_gist.rb <path to dirname/filename> <public? (boolean)> <"gist description">
