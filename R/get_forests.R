forest_names <- dir(forests_folder, pattern='.*.rf')
forests <- paste(forests_folder, forest_names,sep="/")
print(forests)
for (forest in forests)
{
  load(file=forest)
}

