packages <- c("plotly","tidyverse","knitr","kableExtra","fastDummies","rgl","car",
             "reshape2","jtools","lmtest","caret","pROC","ROCR","nnet","magick",
             "cowplot")

if(sum(as.numeric(!packages %in% installed.packages())) != 0){
  installer <- packages[!packages %in% installed.packages()]
  for(i in 1:length(installer)) {
    install.packages(installer, dependencies = T)
    break()}
  sapply(packages, require, character = T) 
} else {
  sapply(packages, require, character = T) 
}

load("../../../data/challenger.RData")

challenger %>%
  kable() %>%
  kable_styling(bootstrap_options = "striped", 
                full_width = F, 
                font_size = 22)

summary(challenger)

challenger %>%
  mutate(failure = ifelse(number_failures > 0,
                        yes = "yes",
                        no = "no"),
         failure = factor(failure)) -> challenger

challenger %>%
  select(number_failures, failure, everything()) %>%
  kable() %>%
  kable_styling(bootstrap_options = "striped",
                full_width = F,
                font_size = 22)

#Binary Logistic Model
model_challenger <- glm(formula = failure ~ . -number_failures -t,
                        data = challenger,
                        family = "binomial")

summary(model_challenger)

summ(model = model_challenger, confint = T, digits = 4, ci.width = 0.95)
export_summs(model_challenger, scale = F, digits = 4)

#Stepwise
step_challenger <- step(object = model_challenger,
                        k = qchisq(p = 0.05, df = 1, lower.tail = FALSE))

summ(model = step_challenger, confint = T, digits = 4, ci.width = 0.95)

#Sample 1: Failure probability at 70ºF (~21ºC)?
predict(object = step_challenger,
        data.frame(temperature = 70),
        type = "response")

#Sample 2: Failure probability at 77ºF (25ºC)?
predict(object = step_challenger,
        data.frame(temperature = 77),
        type = "response")

#Sample 3: Failure probability at 34ºF (~1ºC)?
predict(object = step_challenger,
        data.frame(temperature = 34),
        type = "response")

ggplotly(
  challenger %>% 
    mutate(phat = predict(object = step_challenger,
                          newdata = challenger,
                          type = "response"),
           failure = as.numeric(failure) - 1) %>% 
    ggplot() +
    geom_point(aes(x = temperature, y = failure), color = "#95D840FF", size = 2) +
    geom_smooth(aes(x = temperature, y = phat), 
                method = "glm", formula = y ~ x, 
                method.args = list(family = "binomial"), 
                se = F,
                color = "#440154FF", size = 2) +
    labs(x = "Temperature",
         y = "Failure") +
    theme_bw()
)