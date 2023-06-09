# install and load packages
pacman::p_load(tidyverse)


# R 3.2 Probability of delay

# R 3.2.1 Generative simulation
sim_rides <- function(N, p){
  sample(c("L", "O"), size=N, replace=TRUE, prob=c(p, 1-p)) 
}



# R 3.2.2 Statistical model (estimator)
compute_post <- function(obs, poss){ 
  
  L <- sum(obs=="L") # data
  O <- sum(obs=="O")
  ways <- sapply( poss , function(q) (q*4)^L * ((1-q)*4)^O ) 
  post <- ways/sum(ways) # relative number
  data.frame(poss, ways, post=round(post,3)) # summary
  
}
data <- c("L", "O", "L")
compute_post(obs = data, poss=seq(0,1,.25))


# R 3.2.3 Integrate prior knowledge
data <- c("L", "O", "L")
prior <- compute_post(obs = data, poss=seq(0,1,.25))
new <- compute_post(obs = "O", poss=seq(0,1,.25))
prior$ways * new$ways # absolute ways
round((prior$post * new$post)/sum(prior$post * new$post), 2) # relative 


# R 3.2.4 Bayesian updating with grid approximation

# define prior 
poss <- tibble(theta = seq(0,1,.05), 
               prior = rep(1/length(theta),length(theta)))


# statistical model
compute_post <- function(obs, poss){ 
  L <- sum(obs=="L")
  likelihood <- dbinom(L, N, prob = poss$theta)
  posterior <- likelihood*poss$prior
  posterior_norm <- posterior/sum(posterior)
  tibble(poss,lh=round(likelihood, 3), post=round(posterior_norm,3))
}

# estimation 
N <- 9
obs <- sim_rides(N, p = .5)
estimation <- compute_post(obs, poss)


# Check results
estimation
estimation %>% 
  pivot_longer(cols = c(prior,post), names_to = "type", values_to = "probability") %>% 
  ggplot(aes(x=theta, y = probability, color = type, linetype = type)) + 
  geom_line(size = 1) + 
  theme_minimal() + 
  labs(x = "Theta", 
       y = "Probability", 
       color = "Probability",
       linetype = "Probability")



# Step-wise updating and the value of more data 

compute_post <- function(obs, poss){ 
  L <- sum(obs=="L")
  likelihood <- dbinom(L, 1, prob = poss$theta)
  posterior <- likelihood*poss$prior
  posterior_norm <- posterior/sum(posterior)
  tibble(poss,lh=round(likelihood, 3), post=round(posterior_norm,3))
}

N <- 9
p <- .5
samples <- vector("numeric", N)
results <- vector("list", N)
poss <- tibble(theta = seq(0,1,.05), 
               prior = rep(1/length(theta),length(theta)))
for (i in seq_along(1:N)){
  
  # sample new data
  samples[i] <- sample(c("L", "O"), size=1, replace=TRUE, prob=c(p, 1-p))
  
  estimation <- compute_post(samples[i], poss)
  results[[i]] <- expand_grid(N = i, estimation)
  
  poss$prior <- estimation$post
  
}


# examine updating process
label <- tibble(N = 1:N,  samples)
plot <- results %>% 
  bind_rows() %>% 
  pivot_longer(cols = c(prior, post), names_to = "type", values_to = "probability") %>% 
  ggplot(aes(x=theta, y = probability)) + 
  facet_wrap(~N) +
  geom_line(aes(linetype = type, color = type), size = 1) + 
  theme_minimal() + 
  labs(x = "Theta", 
       y = "Probability", 
       color = "Probability",
       linetype = "Probability")

plot + geom_text(
  data    = label,
  mapping = aes(x = -Inf, y = -Inf, label = samples),
  hjust   = -1,
  vjust   = -11
)