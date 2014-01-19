#### function for setting main DF 
forestDF <- function(object, study, n.e, event.e, mean.e, sd.e,
                     n.c, event.c, mean.c, sd.c, effect, se, 
                     w.fixed, w.random, mean, lower, upper,
                     e.lower, e.upper, summary = FALSE){
  if (inherits(object, "metabin")) {
   DF <- data.frame(study = study, n.e = n.e, event.e = event.e,
                    n.c = n.c, event.c = event.c, effect = effect,
                    se = se, w.fixed = w.fixed, w.random = w.random,
                    mean = mean, lower = lower, upper = upper,
                    e.lower = e.lower, e.upper = e.upper)
   
   if (!is.null(object$byvar)) {
     if (summary == FALSE) DF <- cbind(DF, group = object$byvar)
     else DF <- cbind(DF, group = "")     
   } 
   
  } 
  if (inherits(object, "metacont")) {
   DF <-  data.frame(study = study, n.e = n.e, mean.e = mean.e, sd.e = sd.e,
                     n.c = n.c, mean.c = mean.c, sd.c = sd.c, effect = effect,
                     se = se, w.fixed = w.fixed, w.random = w.random,
                     mean = mean, lower = lower, upper = upper)
   
   if (!is.null(object$byvar)) {
     if (summary == FALSE) DF <- cbind(DF, group = object$byvar)
     else DF <- cbind(DF, group = "")   
   }
  }
  DF
}



#### set up generic function 
meta2DF <- function(object, ...) UseMethod("meta2DF")

##======metabin======##
meta2DF.metabin <- function(meta, add = NULL, rowOrder = NULL,
                            title = NULL, subtitle = NULL, ...){
  ## step 1: the set up of the main data frame
  # summary meta data
  sum.meta <- summary(meta)
  # set up main data frame
  DF <- forestDF(meta, study = meta$studlab, n.e = meta$n.e, 
                 event.e = meta$event.e, n.c = meta$n.c, se = meta$seTE,
                 event.c = meta$event.c, effect = exp(meta$TE),  
                 w.fixed = (meta$w.fixed / sum(meta$w.fixed) * 100),
                 w.random = (meta$w.random / sum(meta$w.fixed) * 100),
                 mean = meta$TE, lower = sum.meta$study$lower,
                 upper = sum.meta$study$upper, 
                 e.lower = exp(sum.meta$study$lower), 
                 e.upper = exp(sum.meta$study$upper),
                 summary = FALSE)
  
  
  ## step 2: the set up of the fixed effect and the random effect
  # fixed effect
  summary.fixed <- forestDF(meta, study = "Fixed effect",
                            n.e = sum(meta$n.e), event.e = NA,
                            n.c = sum(meta$n.c), event.c = NA,
                            effect = exp(meta$TE.fixed),
                            se = meta$seTE.fixed, w.fixed = 100,
                            w.random = 0, mean = meta$TE.fixed,
                            lower = sum.meta$fixed$lower,
                            upper = sum.meta$fixed$upper,
                            e.lower = exp(sum.meta$fixed$lower),
                            e.upper = exp(sum.meta$fixed$upper),
                            summary = TRUE)
  
  # random effect 
  summary.random <- forestDF(meta, study = "random effect",
                             n.e = NA, event.e = NA, 
                             n.c = NA, event.c = NA,
                             effect = exp(meta$TE.random),
                             se = meta$seTE.random,
                             w.fixed = 0, w.random= 100,
                             mean = meta$TE.random,
                             lower = sum.meta$random$lower,
                             upper = sum.meta$random$upper,
                             e.lower = exp(sum.meta$random$lower),
                             e.upper = exp(sum.meta$random$upper),
                             summary = TRUE)
  
  
  ## step 3: customization on the main data frame
  # attach additional columns to the meta object
  if (!is.null(add)) {
    # attach the additional column to the main data frame
    DF <- cbind(DF, add)
    # attach the corresponding space to the summary data frame
    addspace <- lapply(add, function(x){x <- ""})
    summary.fixed <- cbind(summary.fixed, addspace)
    summary.random <- cbind(summary.random, addspace)    
  }
  
  # specify row orders
  if (!is.null(rowOrder)) {
    Order <- order(DF[, rowOrder], ...)
    DF <- DF[Order, ]
  }
  
  ## step 4: heterogeneity information
  hetero <- c(Q = sum.meta$Q, df = sum.meta$k - 1,
              p = pchisq(sum.meta$Q, sum.meta$k - 1, lower.tail = FALSE),
              tau2 = sum.meta$tau^2,
              H = sum.meta$H$TE,
              H.lower = sum.meta$H$lower,
              H.upper = sum.meta$H$upper,
              I2 = sum.meta$I2$TE,
              I2.lower = sum.meta$I2$lower,
              I2.upper = sum.meta$I2$upper,
              Q.CMH = sum.meta$Q.CMH)
  
    
  
  ## step 5: Grouped Studies
  if (!is.null(meta$byvar)){
    Group <- list()
    gp <- DF["group"]
    for (i in 1:max(gp)){
      ## set up of the main DF for the group
      df <- DF[gp == i, ]
      
      ## fixed effect for the group
      group.fixed <- forestDF(meta, study = "Fixed Effect",
                              n.e = sum(meta$n.e[gp == i]), event.e = NA,
                              n.c = sum(meta$n.c[gp == i]), event.c = NA,
                              effect = exp(sum.meta$within.fixed$TE[i]),
                              se = sum.meta$within.fixed$seTE[i], w.fixed = 0,
                              w.random = 0, mean = sum.meta$within.fixed$TE[i],
                              lower = sum.meta$within.fixed$lower[i],
                              upper = sum.meta$within.fixed$upper[i],
                              e.lower = exp(sum.meta$within.fixed$lower[i]),
                              e.upper = exp(sum.meta$within.fixed$upper[i]),
                              summary = TRUE)
      # random effect 
      group.random <- forestDF(meta, study = "Random Effect",
                               n.e = NA, event.e = NA, 
                               n.c = NA, event.c = NA,
                               effect = exp(sum.meta$within.random$TE[i]),
                               se = sum.meta$within.random$seTE[i],
                               w.fixed = 0, w.random= 0, 
                               mean = sum.meta$within.random$TE[i],
                               lower = sum.meta$within.random$lower[i],
                               upper = sum.meta$within.random$upper[i],
                               e.lower = exp(sum.meta$within.random$lower[i]),
                               e.upper = exp(sum.meta$within.random$upper[i]),
                               summary = TRUE)
      
      # heterogeneity information for the group
      hetero.w <- c(Q = sum.meta$Q.w[i], df = sum.meta$k.w[i] - 1,
                    p = pchisq(sum.meta$Q.w[i], sum.meta$k.w[i] - 1, lower.tail = FALSE),
                    tau2 = sum.meta$tau.w[i]^2,
                    H = sum.meta$H.w$TE[i],
                    H.lower = sum.meta$H.w$lower[i],
                    H.upper = sum.meta$H.w$upper[i],
                    I2 = sum.meta$I2.w$TE[i],
                    I2.lower = sum.meta$I2.w$lower[i],
                    I2.upper = sum.meta$I2.w$upper[i])
      # set up the group
      Group[[i]] <- list(DF = df, summary.fixed = group.fixed,
                         summary.random = group.random, hetero = hetero.w)
      
    } 
  }

  ## step 6: the set up of titles
  title <- title
  subtitle <- subtitle
  
  ## step 7: the wrap up
  if (!is.null(meta$byvar)){
    output <- list(Group = Group, overall.fixed = summary.fixed,
                  overall.random = summary.random, hetero = hetero,
                  title = title, subtitle = subtitle)
    class(output) <- c("groupedMetaDF", "metabinDF", "metaDF")
  }
  else{
    output <- list(DF = DF, summary.fixed = summary.fixed,
                   summary.random = summary.random, hetero = hetero)
    class(output) <- c("metabinDF", "metaDF")
  }
  output  
}

##======metacont======##
meta2DF.metacont <- function(meta, add = NULL, rowOrder = NULL,
                             title = NULL, subtitle = NULL, ...){
  ## step 1: the set up of the main data frame
  # summary meta data
  sum.meta <- summary(meta)
  # set up the main data frame
  DF <- forestDF(meta, study = meta$studlab, n.e = meta$n.e,
                 mean.e = meta$mean.e, sd.e = meta$sd.e,
                 n.c = meta$n.c, mean.c = meta$mean.c, sd.c = meta$sd.c,
                 effect = meta$TE, se = meta$seTE,
                 w.fixed = meta$w.fixed / sum(meta$w.fixed) * 100,
                 w.random = meta$w.random / sum(meta$w.random) * 100,
                 mean = meta$TE, lower = sum.meta$study$lower,
                 upper = sum.meta$study$upper)
  
  ## step 2: the set up of the fixed effect and the random effect
  # fixed effect
  summary.fixed <- forestDF(meta, study = "Fixed effect",
                            n.e = sum(meta$n.e), mean.e = NA, sd.e = NA,
                            n.c = sum(meta$n.c), mean.c = NA, sd.c = NA,
                            effect = meta$TE.fixed, se = meta$seTE.fixed,
                            w.fixed = 100, w.random = 0, mean = meta$TE.fixed,
                            lower = sum.meta$fixed$lower, 
                            upper = sum.meta$fixed$upper, summary = TRUE)
  
  # random effect
  summary.random <- forestDF(meta, study = "Random effect",
                             n.e = NA, mean.e = NA, sd.e = NA,
                             n.c = NA, mean.c = NA, sd.c = NA,
                             effect = meta$TE.random, se = meta$seTE.random,
                             w.fixed = 0, w.random = 100, mean = meta$TE.random, 
                             lower = sum.meta$random$lower, 
                             upper = sum.meta$random$upper, summary = TRUE)
  
  ## step 3: customization on the main data frame
  # attach additional columns to the meta object
  if (!is.null(add)){
    # attach the additional column to the main data frame
    DF <- cbind(DF, add)
    # attach the corresponding space to the summary data frame
    addspace <- lapply(add, function(x){x <- ""})
    summary.fixed <- cbind(summary.fixed, addspace)
    summary.random <- cbind(summary.random, addspace)
  }
  
  # specify row orders
  if (!is.null(rowOrder)) {
    order <- order(DF[, rowOrder], ...)
    DF <- DF[order, ]
  }
  
  # step 4: heterogenity information
  hetero <- c(Q = sum.meta$Q, df = sum.meta$k - 1,
              p = pchisq(sum.meta$Q, sum.meta$k - 1, lower.tail =FALSE),
              tau2 = sum.meta$tau^2,
              H = sum.meta$H$TE,
              H.lower = sum.meta$H$lower,
              H.upper = sum.meta$H$upper,
              I2 = sum.meta$I2$TE,
              I2.lower = sum.meta$I2$lower,
              I2.upper = sum.meta$I2$upper,
              Q.CMH = sum.meta$Q.CMH)
  
  ## step 5: grouped studies
  if (!is.null(meta$byvar)){
    Group <- list()
    gp <- DF["group"]
    for (i in 1:max(gp)){
      # set up of the main DF for the group
      df <- DF[gp == i, ]
      # fixed effect for the group
      group.fixed <- forestDF(meta, study = "Fixed Effect",
                              n.e = sum(meta$n.e[gp == i]), 
                              mean.e = NA, sd.e = NA,
                              n.c = sum(meta$n.c[gp == i]),
                              mean.c = NA, sd.c = NA,
                              effect = sum.meta$within.fixed$TE[i],
                              se = sum.meta$within.fixed$seTE[i],
                              w.fixed = 0, w.random = 0,
                              mean = sum.meta$within.fixed$TE[i],
                              lower = sum.meta$within.fixed$lower[i],
                              upper = sum.meta$within.fixed$upper[i], 
                              summary = TRUE)
      # random effect for the group
      group.random <-forestDF(meta, study = "Random Effect",
                              n.e = NA, mean.e = NA, sd.e = NA,
                              n.c = NA, mean.c = NA, sd.c = NA,
                              effect = sum.meta$within.random$TE[i],
                              se = sum.meta$within.random$seTE[i],
                              w.fixed = 0, w.random = 0,
                              mean = sum.meta$within.random$TE[i],
                              lower = sum.meta$within.random$lower[i],
                              upper = sum.meta$within.random$upper[i], 
                              summary = TRUE)
      
      # heterogeneity information for the group
      hetero.w <- c(Q = sum.meta$Q.w[i], df = sum.meta$k.w[i] - 1,
                    p = pchisq(sum.meta$Q.w[i], sum.meta$k.w[i] - 1, lower.tail = FALSE),
                    tau2 = sum.meta$tau.w[i]^2,
                    H = sum.meta$H.w$TE[i],
                    H.lower = sum.meta$H.w$lower[i],
                    H.upper = sum.meta$H.w$upper[i],
                    I2 = sum.meta$I2.w$TE[i],
                    I2.lower = sum.meta$I2.w$lower[i],
                    I2.upper = sum.meta$I2.w$upper[i])
      
      # set up the group
      Group[[i]] <- list(DF = df, summary.fixed = group.fixed,
                         summary.random = group.random, hetero = hetero.w)
    }
  }
  
  ## step 6: the set up of the titles
  title <- title
  subtitle <- subtitle
  
  ## step 7: the wrap up
  if (!is.null(meta$byvar)) {
    output <- list(Group = Group, overall.fixed = summary.fixed,
                   overall.random = summary.random, hetero = hetero,
                   title = title, subtitle = subtitle)
    class(output) <- c("groupedMetaDF", "metacontDF", "metaDF") 
  }
  else{
    output <- list(DF = DF, summary.fixed = summary.fixed,
                   summary.random = summary.random, hetero = hetero,
                   title = title, subtitle = subtitle)
    class(output) <- c("metacontDF", "metaDF")
  }
  output
}

