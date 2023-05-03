
# Lessons Learnt

This file contains some lessons I learnt while learning R Shiny, building this 
app, and then deploying it on Azure. Basically a blog page.


## Learning R Shiny

I started by going through our internal "Introduction to Shiny" course which
helped lay a solid foundation. 

I learn best by building minimal examples and playing around with them until
they break, and this is exactly what the course does. You start with a very
simple app linking a slider to a histogram, and then go on to add more inputs
and outputs. Each chapter starts by creating a problem and then showing how
you fix it. 

You very quickly get into the meat of reactivity and how to control the flow
of the app.  

The final chapter looks at UI design - grid layouts, a little HTML and CSS, 
tabs, and `{shinydashboard}`.


The next step was to start reading "mastering shiny" and "Engineering Shiny".
There are a few really useful things that are not included in the "Intro"
course, notably shiny modules, and reactive vals. 

After this I went back and spent quite a long time trying to really understand 
how the reactivity 
worked. Why a reactive value `reactiveVal()` can be considered an 
"input" as it is "lazy", vs. why a download button is an "output" that is 
"eager", when to make reactive expressions `reactive()` and `eventReactive()` 
to create intermediate "conductors", and what all this means for the flow of 
information in the app. 
  
I really struggled making a UI design I was happy with, but I was trying not to
focus on it to much. This is an area where you could sink a lot of time! 


* https://mastering-shiny.org/
* https://engineering-shiny.org/


## Building this app

> Design > prototype > build > strengthen > deploy 
 - From Engineering Shiny 

I sketched out the design on paper first. Engineering Shiny suggests building
the UI first, but my MVP required the quiz section mechanics to work. 
By only drawing a quick sketch and a minimal UI first I could focus on the
core quiz engine. 

I was glad I focused my learning on reactivity as controlling the quiz section
was harder than I had anticipated. I started by just going for it, but quickly
ran into issues where things would update at the wrong time. 
I took a step back and wrote out on paper the chain of events and identified
four "states" the app would be in. Only when moving from one state to the 
next did I want things to update. 
This introduced using reactive vals to hold the state of the
module, and to anchor reactive dependencies onto these. 
There are probably still better ways to do this, but this worked for me. 

Once I had the basic user flow down I circled back to the UI design. Here I 
added columns, padding/margins, and other CSS to nudge everything into the
right place. I also styled it here too, and added the Bulgarian flag. 

After I was happy with my prototype, I re-factored this into a Shiny Module
so I could parameterise it for each quiz topic. I then added the vocab module
which is very simple, and then the start/home page. 

At this point the app was only ~500 lines long and basically looks as it
does now. 

Throughout Engineering Shiny the author says to start with `{golem}` from the
very beginning. I did not do this. My MVP was small enough and I did not 
want the overhead of trying to package everything while still learning. 

But, it is much easier to use `{golem}` to help deploy your app, and so I
re-factored the code. This was not as bad as suggested as my app was already
well modularised. It was quite awkward still, and Engineering Shiny misses a 
few important steps, but I had it re-factored in about a day, (with help)
and then cleaned up after another. I don't regret doing it this
way, although if my app was much bigger it would have been much harder. 

I was then able to generate the package bundle, and docker files easily. 


## Deploying on Azure

Even following Microsoft tutorials you still run into issues. 

This is one where the more you do on Azure, the more familiar you are with the
way it does things, so you can debug quicker, but its still never easy.
I don't have too much to say
here other than I had help from colleagues and did a lot of googling, despite
having seen a lot of this before. I've written up what I learnt in the   
Azure_Deployment_Instructions.md file. 
 

## Next steps

There is a lot left to learn, with several different directions from here.

You could spend a long time developing very pretty UIs for example, 
or dive into making complex apps with dynamic UIs, multiple pages, input from
graphs/tables, and more JavaScript. Alternatively, there is a lot to learn
on the deployment side - how would you manage user profiles, authentication, 
and a database back end?

