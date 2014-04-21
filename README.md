Cleaning and analysis of data set from project of Human Activity Recognition Using Smartphones
========================================================

Description of the project and the raw data sets
----------------------
Human Activity Recognition Using Smartphone project is about modeling human activity using accelerometers from the Samsung Galaxy S smartphone.  The data has been collected from 30 subjects for 6 different activities.  The detailed description about the project can be found at [linked phrase]
http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones.  In this course project for Getting and Cleaning Data, we practice how to make tidy data and performing simple analysis using R.

### Data download
The data is downloaded from the site [linked phrase]https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip  using the following code.
```
# download data and unzip the files
url<-'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
download.file(url, destfile='project')
date_downloaded<-date()
unzip(project)
```
### Structure of raw data sets
The data are divided into two large data sets -- the training sets contain data from subjects whose data are used for training in machine learning and the test sets contain data for testing machine learning algorithm.  For each data sets, data are distributed in three text files, the *X_\\*.txt* contains the the main data body, the *subject_\*.txt* contains information about the corresponding subjects to the data, and the *y_\*.txt* contains information about activity status for the subjects, which is coded from 1 to 6. The three files for the training set and test set can be found in the sub folder 

The names of different variables in the main data body is stored in the *features.txt* file and the code book for the 6 different categories of activity is in *activity_labels.txt*.  

Merging all data into a big data frame
-----------------------------------
All data are read into R as data frames using read.table function.  I first combine main body of data with the subject and activity information using cbind for both training and test data sets.  

### For the test data:
```
test_df<-read.table('./UCI HAR Dataset/test/X_test.txt')
test_sub<-read.table('./UCI HAR Dataset/test/subject_test.txt')
test_activitylabel<-read.table('./UCI HAR Dataset/test/y_test.txt')
test_all<-cbind(test_sub, test_activitylabel, test_df)
```
### For the training data:
```
train_df<-read.table('./UCI HAR Dataset/train/X_train.txt')
train_sub<-read.table('./UCI HAR Dataset/train/subject_train.txt')
train_activitylabel<-read.table('./UCI HAR Dataset/train/y_train.txt')
train_all<-cbind(train_sub, train_activitylabel, train_df)
```
Because there is no overlap between training and test data sets, I use rbind to combine the two data sets into one data frame **all_df**.  
```
all_df<-rbind(train_all, test_all)
```
To label the column names in the all_df using information from *features.txt*, I first read the file into a dataframe **feature**. A vector for column names **col_name_vector** is then created by combining the "Subject" and "Activity_Label" with elements in the second column of feature.  Finally, the value to **col_name_vector** is passed into the **all_df** dataframe using *colnames* function
```
feature<-read.table('./UCI HAR Dataset/features.txt')
col_name_vector<-c('Subject','Activity_Label',as.character(feature[[2]]))
colnames(all_df)<-col_name_vector
```
Now the **all_df** dataframe contains all data from training and test data sets with both subject and activity information.  It is noticed that activity information is still coded by 1 to 6 at this stage.

Select only the variables that are mean and standard deviation for each measurement
------------
This is achieved by checking if the column name contains exact strings of "-mean()" or "-std()" to using grepl function, which create a logical vector with the same length of the **col_name_vector**.  I would also like to keep the "Subject" and "Activity_Label" columns.
The final selection were combined into the logical vector "col_select" by **union** operation.
```
mean_col<-grepl('-mean()', col_name_vector, fixed=TRUE)
std_col<-grepl('-std()', col_name_vector, fixed=TRUE)
sub_col<-grepl('Subject', col_name_vector)
al_col<-grepl('Activity_Label', col_name_vector)
col_select<-mean_col|std_col|sub_col|al_col
```
The original dataframe is subseted using **col_select** to get the dataframe **df_meanstd**, which only contain variable on means and standard deviations.
```
df_meanstd<-all_df[,col_select]
```
Substitute the number coded activity label with descriptive activity names
-------------
I first read the activity names into a dataframe **activity_lables** from file "activity_labels.txt" and then extracted the names of activity as a character vector into **act_lab**.
```
activity_labels<-read.table('./UCI HAR Dataset/activity_labels.txt')
actlab_vect<-as.character(activity_labels[[2]])
```
Using a for loop, I substitute the number code in the "Activity_Label" column with the character names in the actlab vector by first checking which rows have the Activity_label of 1, 2, ... etc, followed substitution.
```
for (i in 1:nrow(activity_labels)){
    index<-which(df_meanstd$Activity_Label==activity_labels[i,1])
    df_meanstd[index,]$Activity_Label<-actlab_vect[i]
    all_df[index,]$Activity_Label<-actlab_vect[i]
}
```
The substitution is done for both the original data set and the data set containing only means and standard deviations.

Create a tidy data set that containing the average of means and standard deviations for each subject and each activity
------------------
Because the data need to be split using two factors -- Subject and Activity_Label, I changed these two columns into factors, f1 and f2 respectively, using the following code.
```
f1<-as.factor(all_df$Subject)
f2<-ordered(all_df$Activity_Label, levels=as.character(activity_labels$V2))
```
f1 has 30 levels and f2 has 6 levels.  The the dataframe is splited according to the combinations of these two factors, which has 30\*6=180 levels.  Means of each columns except the first two columns containing the factorial information are calculated using **sapply** and inline function **colMeans**.  The calculation is done on both the original data set and the data set containing only means and standard deviations.
### The code for original data set:
```
s_df<-split(all_df,list(f1,f2))
n_col<-ncol(all_df)
sum<-sapply(s_df, function(y) colMeans(y[,3:n_col]))
```
### The code for the mean and std data set:
```
s_df_meanstd<-split(df_meanstd, list(f1, f2))
n_col_meanstd<-ncol(df_meanstd)
sum_meanstd<-sapply(s_df_meanstd, function(y) colMeans(y[,3:n_col_meanstd]))
```
The resulting dataframes from sapply have the row names in the format of "n.activity" where n represent the subject and activity is the descriptive name of the activity.  Therefore, I reconstructed the two columns with one containing subject information and the other containing activity description.  
```
sub<-data.frame(Subject=rep(1:30, times=6))
act<-data.frame(Activity=rep(actlab_vect, each=30))
```
In addition, the dataframes contain 180 columns corresponding to averages on the 180 levels, ie the combination of subjects and activities.  Because we need to have each row representing one observation in a tidy data set, I transpose the rows and columns in the sum and sum_meanstd.  The transposed data body is subsequently combined with the subject and activity columns and the resulting final output dataframes are write to text files.
### The code for original data set:
```
tp_sum<-as.data.frame(t(sum))
output<-cbind(sub, act, tp_sum, row.names=NULL)
write.table(output, './tidydata.txt', sep='\t')
```
### The code for the mean and std data set:
```
tp_sum_meanstd<-as.data.frame(t(sum_meanstd))
output_meanstd<-cbind(sub, act, tp_sum_meanstd, row.names=NULL)
write.table(output_meanstd, './tidydata_meanstd.txt', row.names=F)
```

























