# part 1: read data into data frames, and merge into a single data frame

test_df<-read.table('./UCI HAR Dataset/test/X_test.txt')
test_sub<-read.table('./UCI HAR Dataset/test/subject_test.txt')
test_activitylabel<-read.table('./UCI HAR Dataset/test/y_test.txt')
test_all<-cbind(test_sub, test_activitylabel, test_df)

train_df<-read.table('./UCI HAR Dataset/train/X_train.txt')
train_sub<-read.table('./UCI HAR Dataset/train/subject_train.txt')
train_activitylabel<-read.table('./UCI HAR Dataset/train/y_train.txt')
train_all<-cbind(train_sub, train_activitylabel, train_df)

all_df<-rbind(train_all, test_all)

feature<-read.table('./UCI HAR Dataset/features.txt')
col_name_vector<-c('Subject','Activity_Label',as.character(feature[[2]]))
colnames(all_df)<-col_name_vector

# part 2: select columns containing only mean and std of each measurement

mean_col<-grepl('mean', col_name_vector)
std_col<-grepl('std', col_name_vector)
meanfreq_col<-grepl('meanFreq', col_name_vector)
col_select<-(mean_col|std_col)&(!meanfreq_col)
col_select[1:2]<-TRUE

df_meanstd<-all_df[,col_select]

# part 3/4: put descriptive activity label in the data frames (for both the 
# complete data set and the data set contain only mean and std)
activity_labels<-read.table('./UCI HAR Dataset/activity_labels.txt')
actlab_vect<-as.character(activity_labels[[2]])
for (i in 1:nrow(activity_labels)){
    index<-which(df_meanstd$Activity_Label==activity_labels[i,1])
    df_meanstd[index,]$Activity_Label<-actlab_vect[i]
    all_df[index,]$Activity_Label<-actlab_vect[i]
}

# part 5: calculating the average of each variable in the complete data set
# for each subject and each activity
f1<-as.factor(all_df$Subject)
f2<-ordered(all_df$Activity_Label, levels=as.character(activity_labels$V2))
s_df<-split(all_df,list(f1,f2))
n_col<-ncol(all_df)
sum<-sapply(s_df, function(y) colMeans(y[,3:n_col]))
tp_sum<-as.data.frame(t(sum))
sub<-data.frame(Subject=rep(1:30, times=6))
act<-data.frame(Activity=rep(actlab_vect, each=30))
output<-cbind(sub, act, tp_sum, row.names=NULL)
write.table(output, './tidydata.txt', sep='\t')

