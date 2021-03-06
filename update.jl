function copy_to_depot(rel_path)
    depot = first(DEPOT_PATH)
    here = dirname(@__FILE__())
    if !isdir(dirname(joinpath(depot, rel_path)))
        mkpath(dirname(joinpath(depot, rel_path)))
    end
    cp(joinpath(here, rel_path), joinpath(depot, rel_path), force=true)
end

copy_to_depot(joinpath("scripts", "develop.jl"))
copy_to_depot(joinpath("config", "startup.jl"))

@info "Rewritten your startup!"