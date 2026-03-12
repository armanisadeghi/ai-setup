# Arman's List of Agent Tasks

The following are the things that Arman (Lead developer) is asking you to work on.

1. Take the items entered here and organize them each time.
2. If you are unclear, ask Arman questions.
3. Create a task list where each part or the entire task is clearly separated and ensures completion
4. As tasks are completed, they need to be summarized, condensed and moved to the bottom of the list to keep the focus on what is still pending.
5. If things need testing or review, create a quick and direct task asking Arman to test and provide him with specifics on what to test, if necesary.



# Tasks
- Get the git repo, all documentation and all basics for the server fully set up.
- Ensure the settings firles for vscode are also saved to git so that they are not lost. Ideally, it woudl be good to ensure that even these conversations are stored in our git so when the server turns on and off, we don't lose the context, but if we have no choicce, then we need great notes.
- We need to ensure we have everything we need for a modern text to video and image to video setup - you need to brows the web to find the best available workflows and set them up.
- We need to ensure that our workflows, especially the imgage to vidoe, allows for easy addition of Loras
- Arman is a novice when it comes to ComfyUI so it's important that you set up the workflows and all default values based on articles you read and guidance provided by experts.
    - A best practice would be to create multiple variations of some workflows using guidance from different sources and just ask Arman to do a quick test to deetermine which gets the best results.
- Make sure you properly configure ComfyUI to save all data to persistent storage
- We need to properly set up ComfyUI to work via an API so that Arman can hit it from outside and use his AI Matrx Admin UI to access it.
- We are starting with a focus on video, but we will be setting up image and text as well.
- To begin with, it's important that we set up the best version of Flux that we can get our hands on and include some of the best Loras.
- Arman's primary client is a Modeling agency specializing in Women's bikinis and lingerie so it's important that we identify loras that are great for generating images and videos of beautiful women. This is critical for the success of this project.
- Make sure we are properly set up with all of the env values needed to get things from Civit and Huggingface. We need to consider where and how to store envs so that they're safe but don't require Arman to enter them each time.