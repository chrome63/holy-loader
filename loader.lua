
--==================================================
-- HOLY PUBLIC LOADER - V2 PRIVATE SOURCE
--==================================================

local Players =
    game:GetService("Players")

local HttpService =
    game:GetService("HttpService")

local CoreGui =
    game:GetService("CoreGui")

local LocalPlayer =
    Players.LocalPlayer
    or Players.PlayerAdded:Wait()

local API =
    "https://holy-loader-api.benjicapalot041.workers.dev"

local PRODUCT =
    "holy_core"

local SOURCE_ROUTE =
    "/v1/source/holy_core"

local KEY_FILE =
    "HOLY_Key.txt"

local DISCORD_INVITE =
    "https://discord.gg/zUj5NmTA4u"

local PUBLIC_LOADER_URL =
    "https://raw.githubusercontent.com/chrome63/holy-loader/main/loader.lua"

local ALLOWED_UNIVERSE_IDS = {
    [10200395747] =
        true,
}

local LEGACY_ALLOWED_PLACE_IDS = {
    [97598239454123] =
        true,

    [73504898027860] =
        true,
}

local function Clean(value)

    return tostring(
        value
        or ""
    )
        :gsub(
            "^%s+",
            ""
        )
        :gsub(
            "%s+$",
            ""
        )
end

local function GetEnvironment()

    if type(getgenv) == "function" then

        local ok,
            environment =
            pcall(
                getgenv
            )

        if ok == true
        and type(environment) == "table" then

            return environment
        end
    end

    return _G
end

local Environment =
    GetEnvironment()

local function CopyToClipboard(
    value
)

    value =
        tostring(
            value
            or ""
        )

    local attempted = {}

    local function TryCopy(
        callback
    )

        if type(callback) ~= "function"
        or attempted[callback] == true then

            return false
        end

        attempted[callback] =
            true

        local success,
            result =
            pcall(
                callback,
                value
            )

        return success == true
            and result ~= false
    end

    if TryCopy(
        setclipboard
    ) == true
    or TryCopy(
        toclipboard
    ) == true
    or TryCopy(
        rawget(
            Environment,
            "setclipboard"
        )
    ) == true
    or TryCopy(
        rawget(
            Environment,
            "toclipboard"
        )
    ) == true
    or TryCopy(
        rawget(
            Environment,
            "set_clipboard"
        )
    ) == true
    or TryCopy(
        rawget(
            Environment,
            "writeclipboard"
        )
    ) == true then

        return true
    end

    local synTable =
        rawget(
            Environment,
            "syn"
        )

    if type(synTable) == "table"
    and TryCopy(
        synTable.write_clipboard
    ) == true then

        return true
    end

    return false
end

local HOLY_LOADER_CHANNEL =
    "stable"

local existingLoaderRuntime =
    Environment.HOLY_LOADER_RUNTIME
    or _G.HOLY_LOADER_RUNTIME

if type(existingLoaderRuntime) == "table"
and existingLoaderRuntime.JobId == game.JobId
and (
    existingLoaderRuntime.Loading == true
    or existingLoaderRuntime.Loaded == true
) then

    warn(
        "[HOLY]",
        "HOLY is already loading or loaded.",
        "Channel:",
        tostring(
            existingLoaderRuntime.Channel
            or "unknown"
        )
    )

    return
end

local HOLY_LOADER_RUNTIME = {
    JobId =
        game.JobId,

    PlaceId =
        game.PlaceId,

    Channel =
        HOLY_LOADER_CHANNEL,

    Loading =
        true,

    Loaded =
        false,

    StartedAt =
        os.clock(),
}

Environment.HOLY_LOADER_RUNTIME =
    HOLY_LOADER_RUNTIME

_G.HOLY_LOADER_RUNTIME =
    HOLY_LOADER_RUNTIME

Environment.HOLY_PUBLIC_LOADER_RUNNING =
    true

Environment.HOLY_DEV_LOADER_RUNNING =
    false

_G.HOLY_PUBLIC_LOADER_RUNNING =
    true

_G.HOLY_DEV_LOADER_RUNNING =
    false

local function ReleaseHolyLoaderRuntime()

    if Environment.HOLY_LOADER_RUNTIME
        == HOLY_LOADER_RUNTIME then

        Environment.HOLY_LOADER_RUNTIME =
            nil
    end

    if _G.HOLY_LOADER_RUNTIME
        == HOLY_LOADER_RUNTIME then

        _G.HOLY_LOADER_RUNTIME =
            nil
    end

    Environment.HOLY_PUBLIC_LOADER_RUNNING =
        false

    Environment.HOLY_DEV_LOADER_RUNNING =
        false

    _G.HOLY_PUBLIC_LOADER_RUNNING =
        false

    _G.HOLY_DEV_LOADER_RUNNING =
        false

    return true
end

local function WaitForSupportedExperience(
    timeout
)

    local deadline =
        os.clock()
        + (
            tonumber(timeout)
            or 45
        )

    repeat

        local universeId =
            tonumber(
                game.GameId
            )
            or 0

        local placeId =
            tonumber(
                game.PlaceId
            )
            or 0

        if ALLOWED_UNIVERSE_IDS[
            universeId
        ] == true then

            return true,
                universeId,
                placeId,
                "universe"
        end

        if LEGACY_ALLOWED_PLACE_IDS[
            placeId
        ] == true then

            return true,
                universeId,
                placeId,
                "legacy_place"
        end

        task.wait(
            0.25
        )

    until os.clock() >= deadline

    return false,
        tonumber(game.GameId)
        or 0,
        tonumber(game.PlaceId)
        or 0,
        "unsupported"
end

if game:IsLoaded() ~= true then

    game.Loaded:Wait()
end

local supportedExperience,
    resolvedUniverseId,
    resolvedPlaceId =
    WaitForSupportedExperience(
        45
    )

if supportedExperience ~= true then

    ReleaseHolyLoaderRuntime()

    error(
        "[HOLY] This loader cannot run in this experience."
        .. "\nUniverseId: "
        .. tostring(
            resolvedUniverseId
        )
        .. "\nPlaceId: "
        .. tostring(
            resolvedPlaceId
        ),
        0
    )
end

local function GetRequestFunction()

    if type(syn) == "table"
    and type(syn.request) == "function" then

        return syn.request
    end

    if type(http_request) == "function" then

        return http_request
    end

    if type(request) == "function" then

        return request
    end

    if type(fluxus) == "table"
    and type(fluxus.request) == "function" then

        return fluxus.request
    end

    if type(Environment.request) == "function" then

        return Environment.request
    end

    if type(Environment.http_request) == "function" then

        return Environment.http_request
    end

    return nil
end

local function GetQueueFunction()

    if type(queue_on_teleport) == "function" then

        return queue_on_teleport
    end

    if type(queueonteleport) == "function" then

        return queueonteleport
    end

    if type(syn) == "table"
    and type(syn.queue_on_teleport) == "function" then

        return syn.queue_on_teleport
    end

    if type(fluxus) == "table"
    and type(fluxus.queue_on_teleport) == "function" then

        return fluxus.queue_on_teleport
    end

    if type(Environment.queue_on_teleport) == "function" then

        return Environment.queue_on_teleport
    end

    if type(Environment.queueonteleport) == "function" then

        return Environment.queueonteleport
    end

    return nil
end

local function ReadSavedKey()

    if type(readfile) ~= "function" then

        return ""
    end

    local ok,
        value =
        pcall(
            readfile,
            KEY_FILE
        )

    if ok ~= true then

        return ""
    end

    return Clean(
        value
    ):upper()
end

local function SaveKey(key)

    if type(writefile) ~= "function" then

        return false,
            "writefile is unavailable"
    end

    key =
        Clean(
            key
        ):upper()

    local ok,
        saveError =
        pcall(
            writefile,
            KEY_FILE,
            key
        )

    return ok == true,
        ok == true
        and nil
        or tostring(
            saveError
        )
end

local function DecodeJson(body)

    if type(body) ~= "string"
    or body == "" then

        return nil
    end

    local ok,
        decoded =
        pcall(function()

            return HttpService:JSONDecode(
                body
            )
        end)

    if ok == true
    and type(decoded) == "table" then

        return decoded
    end

    return nil
end

local function SendRequest(options)

    local requestFunction =
        GetRequestFunction()

    if type(requestFunction) ~= "function" then

        return nil,
            "Your executor does not support request/http_request."
    end

    local ok,
        response =
        pcall(
            requestFunction,
            options
        )

    if ok ~= true then

        return nil,
            tostring(
                response
            )
    end

    if type(response) == "string" then

        return {
            Success =
                true,

            StatusCode =
                200,

            Body =
                response,
        },
            nil
    end

    if type(response) ~= "table" then

        return nil,
            "Executor returned an invalid HTTP response."
    end

    local statusCode =
        tonumber(
            response.StatusCode
            or response.Status
            or response.status_code
            or response.status
            or 0
        )
        or 0

    local success =
        response.Success

    if success == nil then

        success =
            statusCode >= 200
            and statusCode < 300
    end

    return {
        Success =
            success == true,

        StatusCode =
            statusCode,

        Body =
            tostring(
                response.Body
                or response.body
                or response.ResponseBody
                or response.responseBody
                or ""
            ),
    },
        nil
end

local function FormatApiError(
    decoded,
    fallback
)

    if type(decoded) ~= "table" then

        return tostring(
            fallback
            or "Unknown API error."
        )
    end

    local code =
        Clean(
            decoded.error
            or decoded.code
        ):lower()

    local message =
        Clean(
            decoded.message
        )

    local messages = {
        invalid_key =
            "The HOLY key is invalid.",

        key_not_found =
            "The HOLY key is invalid.",

        missing_key =
            "Enter your HOLY key.",

        license_expired =
            "This HOLY key has expired.",

        license_revoked =
            "This HOLY key has been revoked.",

        license_paused =
            "This HOLY key is currently paused.",

        account_limit_reached =
            "This key has no Roblox account slots remaining.",

        account_not_linked =
            "This Roblox account is not linked to the key.",

        account_identity_mismatch =
            "The saved key session belongs to another Roblox account.",

        product_not_allowed =
            "This key cannot access HOLY Premium.",

        invalid_access_token =
            "The temporary access token was rejected.",

        access_token_expired =
            "The temporary access token expired. Activate the key again.",

        unsupported_place =
            "HOLY does not support this Roblox experience.",

        github_source_fetch_failed =
            "The private HOLY source could not be downloaded.",

        source_fetch_failed =
            "The private HOLY source could not be downloaded.",

        stable_source_not_configured =
            "The stable HOLY source is not configured.",

        source_not_configured =
            "The stable HOLY source is not configured.",

        internal_server_error =
            "The HOLY license service had a server error.",
    }

    return messages[
        code
    ]
        or (
            message ~= ""
            and message
        )
        or (
            code ~= ""
            and code
        )
        or tostring(
            fallback
            or "Unknown API error."
        )
end

local function ActivateKey(key)

    local cleanKey =
        Clean(
            key
        ):upper()

    if cleanKey == "" then

        return nil,
            "Enter your HOLY Premium key."
    end

    local requestBody =
        nil

    local encodeOk,
        encoded =
        pcall(function()

            return HttpService:JSONEncode({
                Key =
                    cleanKey,

                Product =
                    PRODUCT,

                RobloxUserId =
                    tonumber(
                        LocalPlayer.UserId
                    )
                    or 0,

                RobloxUsername =
                    tostring(
                        LocalPlayer.Name
                    ),

                PlaceId =
                    tostring(
                        game.PlaceId
                    ),

                UniverseId =
                    tostring(
                        game.GameId
                    ),
            })
        end)

    if encodeOk ~= true then

        return nil,
            "Could not encode the activation request."
    end

    requestBody =
        encoded

    local response,
        requestError =
        SendRequest({
            Url =
                API
                .. "/v1/license/activate",

            Method =
                "POST",

            Headers = {
                ["Content-Type"] =
                    "application/json",

                ["Accept"] =
                    "application/json",

                ["Accept-Encoding"] =
                    "identity",

                ["Cache-Control"] =
                    "no-cache",
            },

            Body =
                requestBody,
        })

    if response == nil then

        return nil,
            "Activation request failed: "
            .. tostring(
                requestError
            )
    end

    local decoded =
        DecodeJson(
            response.Body
        )

    if response.Success ~= true
    or type(decoded) ~= "table"
    or decoded.ok ~= true then

        return nil,
            FormatApiError(
                decoded,
                "Activation failed with HTTP "
                .. tostring(
                    response.StatusCode
                )
            )
    end

    local role =
        Clean(
            decoded.role
            or decoded.Role
            or "premium"
        ):lower()

    if role ~= "premium"
    and role ~= "staff"
    and role ~= "owner" then

        return nil,
            "The license returned an unsupported role."
    end

    local token =
        Clean(
            decoded.accessToken
            or decoded.access_token
            or decoded.token
        )

    if token == "" then

        return nil,
            "The API did not return an access token."
    end

    local product =
        Clean(
            decoded.product
            or decoded.Product
            or PRODUCT
        ):lower()

    if product ~= PRODUCT then

        return nil,
            "The license returned the wrong product."
    end

    return {
        Key =
            cleanKey,

        Role =
            role,

        Token =
            token,

        Activation =
            decoded,
    },
        nil
end

local function DownloadStableSource(session)

    if type(session) ~= "table" then

        return nil,
            "The license session is missing."
    end

    local response,
        requestError =
        SendRequest({
            Url =
                API
                .. SOURCE_ROUTE,

            Method =
                "GET",

            Headers = {
                ["Authorization"] =
                    "Bearer "
                    .. tostring(
                        session.Token
                        or ""
                    ),

                ["Accept"] =
                    "text/plain",

                ["Accept-Encoding"] =
                    "identity",

                ["Cache-Control"] =
                    "no-cache",
            },
        })

    if response == nil then

        return nil,
            "Source request failed: "
            .. tostring(
                requestError
            )
    end

    if response.Success ~= true then

        return nil,
            FormatApiError(
                DecodeJson(
                    response.Body
                ),
                "Source request failed with HTTP "
                .. tostring(
                    response.StatusCode
                )
            )
    end

    local source =
        tostring(
            response.Body
            or ""
        )

    if source:sub(
        1,
        3
    ) == "\239\187\191" then

        source =
            source:sub(
                4
            )
    end

    if source == "" then

        return nil,
            "The stable source response was empty."
    end

    local preview =
        source:sub(
            1,
            700
        ):lower()

    if preview:find(
        "<!doctype html",
        1,
        true
    )
    or preview:find(
        "<html",
        1,
        true
    ) then

        return nil,
            "The source route returned HTML instead of Lua."
    end

    if preview:find(
        "\"error\"",
        1,
        true
    ) then

        return nil,
            FormatApiError(
                DecodeJson(
                    source
                ),
                "The source route returned an API error."
            )
    end

    local activation =
        session.Activation
        or {}

    local licenseId =
        Clean(
            activation.licenseId
            or activation.LicenseId
        )

    if licenseId == "" then

        return nil,
            "The activation response did not include a license ID."
    end

    local expectedMarker =
        "-- HOLY LICENSE MARKER: PRIVATE-SOURCE"

    if source:sub(
        1,
        #expectedMarker
    ) ~= expectedMarker then

        return nil,
            "The private source marker was missing or invalid."
    end

    if preview:find(
        "-- holy source channel: stable",
        1,
        true
    ) == nil then

        return nil,
            "The API returned the wrong source channel."
    end

    local endMarker =
        "-- HOLY_PREMIUM_END_MARKER"

    if source:find(
        endMarker,
        1,
        true
    ) == nil then

        return nil,
            "The private source download was incomplete. Run the loader again."
    end

    return source,
        nil
end

local function InstallAuth(session)

    local activation =
        session.Activation
        or {}

    local serverFeatures =
        activation.features
        or activation.Features

    local features =
        {}

    if type(serverFeatures) == "table" then

        for featureName,
            enabled in pairs(
            serverFeatures
        ) do

            features[
                featureName
            ] =
                enabled == true
        end
    end

    local licenseId =
        Clean(
            activation.licenseId
            or activation.LicenseId
        )

    local auth = {
        ok =
            true,

        Valid =
            true,

        Dev =
            false,

        Public =
            true,

        Product =
            activation.product
            or activation.Product
            or PRODUCT,

        Plan =
            session.Role,

        Role =
            session.Role,

        role =
            session.Role,

        KeyPrefix =
            activation.keyPrefix
            or activation.KeyPrefix
            or "",

        LicenseId =
            licenseId,

        SessionId =
            table.concat(
                {
                    "v2",
                    tostring(
                        licenseId ~= ""
                        and licenseId
                        or "license"
                    ),
                    tostring(
                        LocalPlayer.UserId
                    ),
                    tostring(
                        os.time()
                    ),
                },
                "_"
            ),

        RobloxUserId =
            tonumber(
                LocalPlayer.UserId
            )
            or 0,

        RobloxUsername =
            tostring(
                LocalPlayer.Name
            ),

        MaxAccounts =
            tonumber(
                activation.maxAccounts
                or activation.MaxAccounts
                or 0
            )
            or 0,

        AccountsUsed =
            tonumber(
                activation.accountsUsed
                or activation.AccountsUsed
                or 0
            )
            or 0,

        ExpiresAt =
            tonumber(
                activation.expiresAt
                or activation.ExpiresAt
                or 0
            )
            or 0,

        SourceChannel =
            "stable",

        Features =
            features,

        features =
            features,
    }

    Environment.HOLY_AUTH =
        auth

    Environment.HOLY_DEV_MODE =
        false

    Environment.HOLY_PUBLIC_MODE =
        true

    Environment.HOLY_DEV_PRODUCT =
        nil

    Environment.HOLY_PUBLIC_PRODUCT =
        PRODUCT

    Environment.HOLY_SOURCE_CHANNEL =
        "stable"

    Environment.HOLY_LICENSE_ROLE =
        session.Role

    _G.HOLY_AUTH =
        auth

    _G.HOLY_DEV_MODE =
        false

    _G.HOLY_PUBLIC_MODE =
        true

    _G.HOLY_DEV_PRODUCT =
        nil

    _G.HOLY_PUBLIC_PRODUCT =
        PRODUCT

    _G.HOLY_SOURCE_CHANNEL =
        "stable"

    _G.HOLY_LICENSE_ROLE =
        session.Role

    return auth
end

local function QueueAfterTeleport()

    local queueState =
        Environment.HOLY_LOADER_QUEUE_STATE
        or _G.HOLY_LOADER_QUEUE_STATE

    if type(queueState) == "table"
    and queueState.FromJobId == game.JobId then

        return true,
            nil
    end

    local queueFunction =
        GetQueueFunction()

    if type(queueFunction) ~= "function" then

        return false,
            "queue_on_teleport is unavailable"
    end

    local reloadUrl =
        PUBLIC_LOADER_URL
        .. "?t="
        .. tostring(
            os.time()
        )

    local queuedCode =
        "task.wait(2)\n"
        .. "loadstring(game:HttpGet("
        .. string.format(
            "%q",
            reloadUrl
        )
        .. ", true))()"

    local ok,
        queueError =
        pcall(
            queueFunction,
            queuedCode
        )

    if ok == true then

        local newQueueState = {
            FromJobId =
                game.JobId,

            Channel =
                HOLY_LOADER_CHANNEL,

            QueuedAt =
                os.clock(),
        }

        Environment.HOLY_LOADER_QUEUE_STATE =
            newQueueState

        _G.HOLY_LOADER_QUEUE_STATE =
            newQueueState
    end

    return ok == true,
        ok == true
        and nil
        or tostring(
            queueError
        )
end

local function CompileSource(source)

    local compiler =
        loadstring
        or load

    if type(compiler) ~= "function" then

        return nil,
            "loadstring/load is unavailable."
    end

    if type(source) ~= "string"
    or source == "" then

        return nil,
            "Compile source is empty."
    end

    local ok,
        chunk,
        compileError =
        pcall(
            compiler,
            source
        )

    if ok ~= true then

        return nil,
            tostring(
                chunk
            )
    end

    if type(chunk) ~= "function" then

        return nil,
            tostring(
                compileError
                or chunk
                or "compiler returned nil"
            )
    end

    return chunk,
        nil
end

local function RunWithKey(key)

    local session,
        activationError =
        ActivateKey(
            key
        )

    if session == nil then

        return false,
            activationError
    end

    local source,
        sourceError =
        DownloadStableSource(
            session
        )

    if source == nil then

        session.Key =
            nil

        session.Token =
            nil

        return false,
            sourceError
    end

    local saved,
        saveError =
        SaveKey(
            session.Key
        )

    if saved ~= true then

        warn(
            "[HOLY] Key authenticated, but could not be saved:",
            tostring(
                saveError
            )
        )
    end

    local auth =
        InstallAuth(
            session
        )

    session.Key =
        nil

    session.Token =
        nil

    local queued,
        queueError =
        QueueAfterTeleport()

    if queued ~= true then

        warn(
            "[HOLY] Teleport queue unavailable:",
            tostring(
                queueError
            )
        )
    end

    print(
        "[HOLY] Authenticated.",
        "Role:",
        tostring(
            auth.Role
        ),
        "User:",
        tostring(
            LocalPlayer.Name
        ),
        "Source: stable"
    )

    local chunk,
        compileError =
        CompileSource(
            source
        )

    source =
        nil

    if chunk == nil then

        return false,
            "Compile failed: "
            .. tostring(
                compileError
            )
    end

    local runOk,
        runError =
        pcall(
            chunk
        )

    if runOk ~= true then

        local failedMainRuntime =
            Environment.HOLY_MAIN_RUNTIME
            or _G.HOLY_MAIN_RUNTIME

        if type(failedMainRuntime) == "table"
        and failedMainRuntime.JobId == game.JobId
        and failedMainRuntime.Loaded ~= true then

            if Environment.HOLY_MAIN_RUNTIME
                == failedMainRuntime then

                Environment.HOLY_MAIN_RUNTIME =
                    nil
            end

            if _G.HOLY_MAIN_RUNTIME
                == failedMainRuntime then

                _G.HOLY_MAIN_RUNTIME =
                    nil
            end
        end

        HOLY_LOADER_RUNTIME.Loading =
            false

        HOLY_LOADER_RUNTIME.Loaded =
            false

        HOLY_LOADER_RUNTIME.LastError =
            tostring(
                runError
            )

        return false,
            "Run failed: "
            .. tostring(
                runError
            )
    end

    HOLY_LOADER_RUNTIME.Loading =
        false

    HOLY_LOADER_RUNTIME.Loaded =
        true

    HOLY_LOADER_RUNTIME.FinishedAt =
        os.clock()

    Environment.HOLY_PUBLIC_LOADER_LOADED =
        true

    _G.HOLY_PUBLIC_LOADER_LOADED =
        true

    return true,
        nil
end

local function AddCorner(
    instance,
    radius
)

    local corner =
        Instance.new(
            "UICorner"
        )

    corner.CornerRadius =
        UDim.new(
            0,
            radius
        )

    corner.Parent =
        instance
end

local function GetUiParent()

    if type(gethui) == "function" then

        local ok,
            result =
            pcall(
                gethui
            )

        if ok == true
        and typeof(result) == "Instance" then

            return result
        end
    end

    if typeof(CoreGui) == "Instance" then

        return CoreGui
    end

    return LocalPlayer:WaitForChild(
        "PlayerGui"
    )
end

local function CreateKeyWindow(
    initialKey,
    initialMessage
)

    local parent =
        GetUiParent()

    local oldGui =
        parent:FindFirstChild(
            "HOLY_Public_Key_UI"
        )

    if oldGui then

        oldGui:Destroy()
    end

    local gui =
        Instance.new(
            "ScreenGui"
        )

    gui.Name =
        "HOLY_Public_Key_UI"

    gui.IgnoreGuiInset =
        true

    gui.ResetOnSpawn =
        false

    gui.DisplayOrder =
        999999

    gui.ZIndexBehavior =
        Enum.ZIndexBehavior.Sibling

    if type(syn) == "table"
    and type(syn.protect_gui) == "function" then

        pcall(
            syn.protect_gui,
            gui
        )
    end

    local parentOk =
        pcall(function()

            gui.Parent =
                parent
        end)

    if parentOk ~= true
    or gui.Parent == nil then

        gui.Parent =
            LocalPlayer:WaitForChild(
                "PlayerGui"
            )
    end

    local window =
        Instance.new(
            "Frame"
        )

    window.AnchorPoint =
        Vector2.new(
            0.5,
            0.5
        )

    window.Position =
        UDim2.fromScale(
            0.5,
            0.5
        )

    window.Size =
        UDim2.fromOffset(
            430,
            252
        )

    window.BackgroundColor3 =
        Color3.fromRGB(
            17,
            18,
            23
        )

    window.BorderSizePixel =
        0

    window.Active =
        true

    window.Draggable =
        true

    window.Parent =
        gui

    AddCorner(
        window,
        12
    )

    local accent =
        Instance.new(
            "Frame"
        )

    accent.Size =
        UDim2.new(
            1,
            0,
            0,
            4
        )

    accent.BackgroundColor3 =
        Color3.fromRGB(
            205,
            54,
            72
        )

    accent.BorderSizePixel =
        0

    accent.Parent =
        window

    local title =
        Instance.new(
            "TextLabel"
        )

    title.Position =
        UDim2.fromOffset(
            24,
            20
        )

    title.Size =
        UDim2.new(
            1,
            -75,
            0,
            30
        )

    title.BackgroundTransparency =
        1

    title.Font =
        Enum.Font.GothamBold

    title.Text =
        "HOLY PREMIUM ACCESS"

    title.TextColor3 =
        Color3.fromRGB(
            245,
            246,
            250
        )

    title.TextSize =
        20

    title.TextXAlignment =
        Enum.TextXAlignment.Left

    title.Parent =
        window

    local close =
        Instance.new(
            "TextButton"
        )

    close.AnchorPoint =
        Vector2.new(
            1,
            0
        )

    close.Position =
        UDim2.new(
            1,
            -18,
            0,
            17
        )

    close.Size =
        UDim2.fromOffset(
            32,
            32
        )

    close.BackgroundColor3 =
        Color3.fromRGB(
            28,
            30,
            38
        )

    close.BorderSizePixel =
        0

    close.Font =
        Enum.Font.GothamBold

    close.Text =
        "X"

    close.TextColor3 =
        Color3.fromRGB(
            190,
            193,
            205
        )

    close.TextSize =
        14

    close.Parent =
        window

    AddCorner(
        close,
        8
    )

    local subtitle =
        Instance.new(
            "TextLabel"
        )

    subtitle.Position =
        UDim2.fromOffset(
            24,
            56
        )

    subtitle.Size =
        UDim2.new(
            1,
            -48,
            0,
            34
        )

    subtitle.BackgroundTransparency =
        1

    subtitle.Font =
        Enum.Font.Gotham

    subtitle.Text =
        "Enter your HOLY Premium key. Valid keys are saved automatically."

    subtitle.TextColor3 =
        Color3.fromRGB(
            155,
            159,
            175
        )

    subtitle.TextSize =
        13

    subtitle.TextWrapped =
        true

    subtitle.TextXAlignment =
        Enum.TextXAlignment.Left

    subtitle.Parent =
        window

    local keyBox =
        Instance.new(
            "TextBox"
        )

    keyBox.Position =
        UDim2.fromOffset(
            24,
            101
        )

    keyBox.Size =
        UDim2.new(
            1,
            -48,
            0,
            46
        )

    keyBox.BackgroundColor3 =
        Color3.fromRGB(
            24,
            26,
            33
        )

    keyBox.BorderSizePixel =
        0

    keyBox.ClearTextOnFocus =
        false

    keyBox.Font =
        Enum.Font.Code

    keyBox.PlaceholderText =
        "HOLY-XXXX-XXXX-XXXX-XXXX"

    keyBox.PlaceholderColor3 =
        Color3.fromRGB(
            103,
            107,
            123
        )

    keyBox.Text =
        Clean(
            initialKey
        ):upper()

    keyBox.TextColor3 =
        Color3.fromRGB(
            238,
            239,
            244
        )

    keyBox.TextSize =
        15

    keyBox.TextXAlignment =
        Enum.TextXAlignment.Left

    keyBox.Parent =
        window

    AddCorner(
        keyBox,
        8
    )

    local padding =
        Instance.new(
            "UIPadding"
        )

    padding.PaddingLeft =
        UDim.new(
            0,
            14
        )

    padding.PaddingRight =
        UDim.new(
            0,
            14
        )

    padding.Parent =
        keyBox

    local activate =
        Instance.new(
            "TextButton"
        )

    activate.Position =
        UDim2.fromOffset(
            24,
            159
        )

    activate.Size =
        UDim2.new(
            1,
            -48,
            0,
            42
        )

    activate.BackgroundColor3 =
        Color3.fromRGB(
            188,
            43,
            61
        )

    activate.BorderSizePixel =
        0

    activate.Font =
        Enum.Font.GothamBold

    activate.Text =
        "ACTIVATE HOLY KEY"

    activate.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    activate.TextSize =
        14

    activate.Parent =
        window

    AddCorner(
        activate,
        8
    )

    local status =
        Instance.new(
            "TextLabel"
        )

    status.Position =
        UDim2.fromOffset(
            24,
            211
        )

    status.Size =
        UDim2.new(
            1,
            -168,
            0,
            24
        )

    status.BackgroundTransparency =
        1

    status.Font =
        Enum.Font.Gotham

    status.Text =
        Clean(
            initialMessage
        )

    status.TextColor3 =
        Color3.fromRGB(
            175,
            178,
            190
        )

    status.TextSize =
        12

    status.TextTruncate =
        Enum.TextTruncate.AtEnd

    status.TextXAlignment =
        Enum.TextXAlignment.Left

    status.Parent =
        window

    local discordButton =
        Instance.new(
            "TextButton"
        )

    discordButton.AnchorPoint =
        Vector2.new(
            1,
            0
        )

    discordButton.Position =
        UDim2.new(
            1,
            -24,
            0,
            211
        )

    discordButton.Size =
        UDim2.fromOffset(
            110,
            24
        )

    discordButton.AutoButtonColor =
        false

    discordButton.BackgroundColor3 =
        Color3.fromRGB(
            24,
            26,
            33
        )

    discordButton.BorderSizePixel =
        0

    discordButton.Font =
        Enum.Font.GothamBold

    discordButton.Text =
        "JOIN DISCORD"

    discordButton.TextColor3 =
        Color3.fromRGB(
            155,
            159,
            175
        )

    discordButton.TextSize =
        10

    discordButton.Parent =
        window

    AddCorner(
        discordButton,
        6
    )

    discordButton.MouseEnter:Connect(function()

        if discordButton.Text
            == "JOIN DISCORD" then

            discordButton.TextColor3 =
                Color3.fromRGB(
                    88,
                    101,
                    242
                )
        end
    end)

    discordButton.MouseLeave:Connect(function()

        if discordButton.Text
            == "JOIN DISCORD" then

            discordButton.TextColor3 =
                Color3.fromRGB(
                    155,
                    159,
                    175
                )
        end
    end)

    discordButton.MouseButton1Click:Connect(function()

        local copied =
            CopyToClipboard(
                DISCORD_INVITE
            )

        discordButton.Text =
            copied == true
            and "COPIED!"
            or "COPY FAILED"

        discordButton.TextColor3 =
            copied == true
            and Color3.fromRGB(
                88,
                101,
                242
            )
            or Color3.fromRGB(
                244,
                102,
                115
            )

        task.delay(
            1.5,
            function()

                if discordButton.Parent then

                    discordButton.Text =
                        "JOIN DISCORD"

                    discordButton.TextColor3 =
                        Color3.fromRGB(
                            155,
                            159,
                            175
                        )
                end
            end
        )
    end)

    local busy =
        false

    local function SetStatus(
        text,
        failed
    )

        status.Text =
            tostring(
                text
                or ""
            )

        status.TextColor3 =
            failed == true
            and Color3.fromRGB(
                244,
                102,
                115
            )
            or Color3.fromRGB(
                144,
                219,
                164
            )
    end

    local function Submit()

        if busy == true then

            return
        end

        local key =
            Clean(
                keyBox.Text
            ):upper()

        if key == "" then

            SetStatus(
                "Enter your HOLY Premium key.",
                true
            )

            return
        end

        busy =
            true

        keyBox.Text =
            key

        keyBox.TextEditable =
            false

        activate.Active =
            false

        activate.AutoButtonColor =
            false

        activate.Text =
            "AUTHENTICATING..."

        SetStatus(
            "Checking license and private stable access...",
            false
        )

        task.spawn(function()

            local success,
                runError =
                RunWithKey(
                    key
                )

            if success == true then

                SetStatus(
                    "Authenticated. Loading HOLY Premium...",
                    false
                )

                task.wait(
                    0.15
                )

                if gui.Parent then

                    gui:Destroy()
                end

                return
            end

            busy =
                false

            keyBox.TextEditable =
                true

            activate.Active =
                true

            activate.AutoButtonColor =
                true

            activate.Text =
                "ACTIVATE HOLY KEY"

            SetStatus(
                tostring(
                    runError
                ),
                true
            )

            warn(
                "[HOLY]",
                tostring(
                    runError
                )
            )
        end)
    end

    close.MouseButton1Click:Connect(function()

        ReleaseHolyLoaderRuntime()

        Environment.HOLY_PUBLIC_LOADER_LOADED =
            false

        _G.HOLY_PUBLIC_LOADER_LOADED =
            false

        gui:Destroy()
    end)

    activate.MouseButton1Click:Connect(
        Submit
    )

    keyBox.FocusLost:Connect(function(
        enterPressed
    )

        if enterPressed == true then

            Submit()
        end
    end)
end

local savedKey =
    ReadSavedKey()

if savedKey ~= "" then

    print(
        "[HOLY] Saved key found. Authenticating..."
    )

    local success,
        runError =
        RunWithKey(
            savedKey
        )

    if success == true then

        return
    end

    warn(
        "[HOLY] Saved key failed:",
        tostring(
            runError
        )
    )

    CreateKeyWindow(
        savedKey,
        tostring(
            runError
        )
    )

    return
end

CreateKeyWindow(
    "",
    "Paste your HOLY Premium key to continue."
)
