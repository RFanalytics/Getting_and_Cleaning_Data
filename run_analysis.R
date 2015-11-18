# R programing project for Coursera - "Getting and Cleaning Data"
# Deadline for submission is 11/22/15
# This programming of R code is based on the assumption that the data files have been downloaded
# into your working directory and unzipped
# Source of data is https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

# The 5 steps listed in the instructions:
# You should create one R script called run_analysis.R that does the following. 
# 1. Merges the training and the test sets to create one data set.
# 2. Extracts only the measurements on the mean and standard deviation for each measurement. 
# 3. Uses descriptive activity names to name the activities in the data set
# 4. Appropriately labels the data set with descriptive variable names. 
# 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

library(data.table)
library(plyr)
library(dplyr)

# The first step is to take a look at the data to get a feel for what is in it.  I used notepad++.
# Things observed are, no headers, there is white space for delimiting, filled rows and columns.

##################################################################
# 1. Merges the training and the test sets to create one data set.
##################################################################

# Look at the unzipped pack of data to see what data sets are needed to fulfill the instructions
# files to read in are: X_train.txt, y_train.txt, subject_train.txt, x_test.txt, y_test.txt and subject_test.txt
# One peculiarity I note is the the "X" in X_train.txt and X_test.txt is a capital X, unlike all other letters - careful.

# read in all 6 of the files noted above

x_train <- read.table("X_train.txt")              # sep by spaces, regular, 7352 rows, 561 columns
y_train <- read.table("y_train.txt")              # this is one long column, 7352 records, values 1-6, Integer-activities
subject_train <- read.table("subject_train.txt")  # long column, 7352 records, values 1-30, Integer-people

x_test <- read.table("X_test.txt")                # sep by spaces, regular, 2947 rows, 561 columns
y_test <- read.table("y_test.txt")                # long column, 2947 records, values 1-6, Integer-activities
subject_test <- read.table("subject_test.txt")    # long column, 297 records, values 2-24, Integer - people

# Next step is to merge the separate data sets for x, y and subject.  These data sets have the same columns
# but different row lengths.  For this operation merge() is not best suited since that will tend
# to merge horizontal (columns). 
# The rbind() will essentially "add" the rows of the two data frames together.

x_merge <- rbind(x_train, x_test)                 # merged data set for x
y_merge <- rbind(y_train, y_test)                 # merged data set for y

people_data <- rbind(subject_train, subject_test) # merged data set for the people

# Noting that it is important to keep the bind order for the test and train data sets 
# in order to correctly associate the people with the data

# It is prudent to remove the original data sets (pretty big) and only keep the merged - preserve memory  
rm(x_train)
rm(y_train)
rm(x_test)
rm(y_test)
rm(subject_train)
rm(subject_test)

# The merged data frames do not have good column names. Reading the features_info.txt file (manually)
# gives good information about what the titles should be

features <- read.table("features.txt")      # features.txt file has all the names for each of the 561 measurements

names(x_merge) <- features$V2               # assign the feature names to the columns

# The data is assembled and now can begin manipulation

############################################################################################
# 2. Extracts only the measurements on the mean and standard deviation for each measurement.
############################################################################################  

# I have interpreted this to mean, only use the column names that have the word (or abreviation)
# of mean or standard deviation.  Columns that do not fit that criteria need to be filtered out.

# by viewing the names in features I can see there are a couple different variations of words standard and mean and need to account for that
# I see "std", "mean", "Mean", I did not see Std so will not search on that

get_names <- grep("std|mean|Mean", names(x_merge))       # this creates a vector with only with column names "std", "mean", and "Mean"
merged_x <- x_merge[ , get_names]                        # makes a new data frame, merged_x, thais reduced from x_merge, based column name vector

rm(x_merge)                                              # no longer need x_merge, and it is big, so get rid of it, merged_x is our data set

############################################################################  
# 3. Uses descriptive activity names to name the activities in the data set.
############################################################################

activities <- read.table("activity_labels.txt")
y_merge[, 1] <- activities[y_merge[, 1], 2]              # put in the activity word to match the index integer
names(y_merge) <- "activity"                             # use the word "activity" for column title
merged_y <- y_merge                                      # rename for consistency with x data

#######################################################################
# 4. Appropriately labels the data set with descriptive variable names.
#######################################################################

names(people_data) <- "person"                          # use the word "person" for subject title        

merged_data <- cbind(merged_x, 
                     merged_y, 
                     people_data)                        # combine the data by columns using cbind for the data frames that were
# used to make one dataframe called merged_data.
# This gives one data frame with the appropriate labeling by appending colums
# identifying the excercise activity and the person tested.

#############################################################################  
# 5. From the data set in step 4, creates a second, independent tidy data set 
# with the average of each variable for each activity and each subject.
#############################################################################

# It is my intent to use dplyr as much as possible through this class as an excercise for
# better learning R programming skills.  Below is the result of much effort for me, I did
# the SWIRL on dplyr twice, and found a nice resource called " Data Wrangling cheat sheet"
# This is a nice card I printed and studied which lead me to the summarise_each function.
# I have to note that it took me a while to realize I needed to use summarise with an "s" vs "z".
# Fooling around with my own test data allowed me to figure out how do implement the steps
# below in a very concise method.  I also like it becasue it avoids assigning a lot of 
# temporary variables that use memory space and then need to be deleted.  The chaining is handy.

tidy_data <- 
  merged_data %>%
  group_by(person,activity) %>%           # order the work by person, then by activity
  summarise_each(funs(mean))              # neat! summarise_each - accross ALL columns

arrange(tidy_data, person, activity)

write.table(tidy_data,"tidy_data.txt",row.name=FALSE)     # write "tidy_data" to the working directory

