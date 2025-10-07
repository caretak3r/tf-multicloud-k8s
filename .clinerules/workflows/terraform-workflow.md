1. ensure you always run `terraform fmt -recursive` after making changes to .tf or .tfvars files
2. when you need to read code from external or internal codebases or chunks of them, always leverage repomix and use that file as context for the next set of tokens
3. Make sure you use repomix on the entire codebase ignoring all files in the .gitignore file. Then scan the project using that xml file. And then lets get to work on making sure all the  modules work for each cloud.
