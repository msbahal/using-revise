import Pkg

function __prep_dev_dir()
    
    # Let's see what project we're in:
    project_toml = Pkg.Operations.project_rel_path(Pkg.Types.Context(), "Project.toml")
    project_dir = dirname(project_toml)
    project_name = basename(project_dir)

    # This is where we'll save our temporariy environments:
    env_dir = joinpath(tempdir(), "julia_dev_env")

    # If our current environment IS already a dev environment, we don't proceed:
    # We could re-activate the original project and rebuild a new temp. environment, but not sure what Revise will do.
    if startswith(project_dir, env_dir)
        println("No! Already dev-ing!")
        return nothing
    end

    # Make up a temp-dir for our dev environment:
    dev_dir = joinpath(env_dir, project_name * "-DEV")

    # Clean it up:
    rm(dev_dir, force=true, recursive=true)
    mkpath(dev_dir)

    # Store where we came from - not used a.t.m., but may be confenient
    write(joinpath(dev_dir, "origin"), project_dir)

    # Read our current project toml:
    lines = readlines(project_toml)

    # Start a new one, adding Revise as well:
    new_toml = ["[deps]",
     "Revise = \"295af30f-e4ad-537b-8983-00126c2a3abe\""]
    
    added = ["Revise"]

    # Now copy all dependencies, also the [test] ones!
    take = false
    for line in lines
        if startswith(lstrip(line), "[")
            take = false
        end

        if (line == "[deps]") || (line == "[extras]")
            take = true
            continue
        end
        
        if take && occursin( "=", line) && strip.(split(line, "="))[2][1] == '"'
            name = strip(split(line, "=")[1])

            if !(name in added)
                push!(new_toml, line)
                push!(added, name)
            end
        end
    end

    # Write them to a new environment file:
    write(joinpath(dev_dir, "Project.toml"), join(new_toml, "\n"))

    # And copy the manifest:
    cp(joinpath(project_dir, "Manifest.toml"), joinpath(dev_dir, "Manifest.toml"))

    # Let's move to the test dir as well
    cd(project_dir)
    cd("test")

    return dev_dir, project_dir
end

# Now, actually do all of the above:
dir, project = __prep_dev_dir()

# And, if that worked, active the development environment:
if (dir != nothing)
    Pkg.activate(dir)

    # For some "test" dependencies, the Manifest may not have entries yet, so resolve:
    Pkg.resolve()

    # Get the packages we don't have yet:
    Pkg.instantiate()

    # And "develop" our current project, so Revise will listen to changes there and we can add it "using OurPackageUnderDevelopment"
    Pkg.develop(Pkg.PackageSpec(path=project))

else
    return
end

using Revise

