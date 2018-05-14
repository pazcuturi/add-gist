This is a Ruby program that receives a dirname or filename and uploads the file or the files in the given directory (and all directories within) as gists into GitHub.

Additionally, the script:
* Displays upload progress
* When upload finishes prints gist’s url
* If a connection error occurs, gives the user an option to resume.

Run instructions:
ruby addGist.rb <dirname/filename> <public? (boolean)