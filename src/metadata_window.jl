module MetadataWindow

using Gtk, Gtk.ShortNames, Gtk.GConstants
using Maple

metadataWindow = nothing

metaDropdownOptions = Dict{String, Any}(
    "IntroType" => Maple.intro_types,
    "ColorGrade" => Maple.color_grades,
    "CoreMode" => Maple.core_modes,
    "CassetteSong" => sort(collect(keys(Main.Maple.Songs.songs)))
)

modeDropdownOptions = Dict{String, Any}(
    "Inventory" => Maple.inventories,
    "StartLevel" => String[]
)

metaFieldOrder = String[
    "Name", "SID", "Icon",
    "CompleteScreenName", "CassetteCheckpointIndex",
    "CassetteNoteColor", "CassetteSong",
    "TitleBaseColor", "TitleAccentColor",
    "TitleTextColor", "IntroType",
    "ColorGrade", "Wipe",
    "DarknessAlpha", "BloomBase", "BloomStrength",
    "Jumpthru", "CoreMode"
]

modeFieldOrder = String[]

function getOptions(data::Dict{String, Any}, dropdownOptions::Dict{String, Any})
    res = Main.ConfigWindow.Option[]

    for (attr, value) in data
        keyOptions = get(dropdownOptions, attr, nothing)
        if isa(value, Bool) || isa(value, Char) || isa(value, String)
            push!(res, Main.ConfigWindow.Option(Main.humanizeVariableName(attr), typeof(value), value, options=keyOptions, dataName=attr))

        elseif isa(value, Integer)
            push!(res, Main.ConfigWindow.Option(Main.humanizeVariableName(attr), Int64, Int64(value), options=keyOptions, dataName=attr))

        elseif isa(value, Real)
            push!(res, Main.ConfigWindow.Option(Main.humanizeVariableName(attr), Float64, Float64(value), options=keyOptions, dataName=attr))
        end
    end

    return res
end

function writeIfExists!(data::Dict{K, V}, key::K, value::V) where {K, V}
    if value !== nothing && !isempty(value)
        data[key] = value

    else
        # Delete the key to make sure any old values are cleared
        delete!(data, key)
    end
end

function addKeyIfAbsent!(data::Dict{K, V}, key::K) where {K, V}
    if !haskey(data, key)
        data[key] = Dict{K, V}()
    end
end

function deleteKeyIfEmpty!(data::Dict{K, V}, key::K) where {K, V}
    if haskey(data, key) && isempty(data[key])
        delete!(data, key)
    end
end

function createWindow()
    targetSide = Main.loadedState.side

    # Fill in possible start room values manually
    modeDropdownOptions["StartLevel"] = String[room.name for room in targetSide.map.rooms]

    metaData = merge(Maple.default_meta, get(targetSide.data, "meta", Dict{String, Any}()))
    metaOptions = getOptions(metaData, metaDropdownOptions)
    metaSection = Main.ConfigWindow.Section("Meta", "meta", metaOptions, metaFieldOrder)

    modeData = merge(Maple.default_mode, get(get(targetSide.data, "meta", Dict{String, Any}()), "mode", Dict{String, Any}()))
    modeOptions = getOptions(modeData, modeDropdownOptions)
    modeSection = Main.ConfigWindow.Section("Mode", "mode", modeOptions, modeFieldOrder)

    sections = Main.ConfigWindow.Section[
        metaSection, modeSection
    ]

    function callback(data::Dict{String, Dict{String, Any}})
        addKeyIfAbsent!(targetSide.data, "meta")
        addKeyIfAbsent!(targetSide.data["meta"], "mode")

        for (attr, value) in data["meta"]
            writeIfExists!(targetSide.data["meta"], attr, value)
        end

        for (attr, value) in data["mode"]
            writeIfExists!(targetSide.data["meta"]["mode"], attr, value)
        end

        deleteKeyIfEmpty!(targetSide.data["meta"], "mode")
        deleteKeyIfEmpty!(targetSide.data, "meta")

        name = get(data["meta"], "Name", targetSide.map.package)
        setproperty!(Main.window, :title, "$(Main.baseTitle) - $name")
    end

    metadataWindow = Main.ConfigWindow.createWindow("$(Main.baseTitle) - Configure Metadata", sections, callback)

    GAccessor.transient_for(metadataWindow, Main.window)

    return metadataWindow
end

function configureMetadata(widget::Gtk.GtkMenuItemLeaf=MenuItem())
    if Main.loadedState.side != nothing
        if metadataWindow !== nothing
            Gtk.destroy(metadataWindow)
        end

        global metadataWindow = createWindow()

        showall(metadataWindow)
    end
end

end