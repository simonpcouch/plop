data(stackoverflow, package = "modeldata")

# some plotting code
ggplot(stackoverflow) + aes(x = YearsCodedJob, y = Salary)
