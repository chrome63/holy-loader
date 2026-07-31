--==================================================
-- HOLY DEV LOADER - V2 PRIVATE SOURCE
--==================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local API = "https://holy-loader-api.benjicapalot041.workers.dev"
local PRODUCT = "holy_core"
local SOURCE_ROUTE = "/v1/source/holy_dev"
local KEY_FILE = "HOLY_Dev_Key.txt"
local DEV_LOADER_URL = "https://raw.githubusercontent.com/chrome63/holy/main/holy_dev_loader_gag2.lua"

local function Clean(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function GetEnvironment()
    if type(getgenv) == "function" then
        local ok, environment = pcall(getgenv)

        if ok and type(environment) == "table" then
            return environment
        end
    end

    return _G
end

local Environment = GetEnvironment()

if Environment.HOLY_DEV_LOADER_RUNNING == true then
    warn("[HOLY DEV] Loader is already running.")
    return
end

Environment.HOLY_DEV_LOADER_RUNNING = true

local function GetRequestFunction()
    if type(syn) == "table" and type(syn.request) == "function" then
        return syn.request
    end

    if type(http_request) == "function" then
        return http_request
    end

    if type(request) == "function" then
        return request
    end

    if type(fluxus) == "table" and type(fluxus.request) == "function" then
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

    if type(syn) == "table" and type(syn.queue_on_teleport) == "function" then
        return syn.queue_on_teleport
    end

    if type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" then
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

    local ok, value = pcall(readfile, KEY_FILE)

    return ok and Clean(value) or ""
end

local function SaveKey(key)
    if type(writefile) ~= "function" then
        return false, "writefile is unavailable"
    end

    local ok, saveError = pcall(writefile, KEY_FILE, Clean(key))

    return ok, ok and nil or tostring(saveError)
end

local function DecodeJson(body)
    if type(body) ~= "string" or body == "" then
        return nil
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    return ok and type(decoded) == "table" and decoded or nil
end

local function SendRequest(options)
    local requestFunction = GetRequestFunction()

    if type(requestFunction) ~= "function" then
        return nil, "Your executor does not support request/http_request."
    end

    local ok, response = pcall(requestFunction, options)

    if not ok then
        return nil, tostring(response)
    end

    if type(response) == "string" then
        return {
            Success = true,
            StatusCode = 200,
            Body = response,
        }, nil
    end

    if type(response) ~= "table" then
        return nil, "Executor returned an invalid HTTP response."
    end

    local statusCode = tonumber(
        response.StatusCode
        or response.Status
        or response.status_code
        or response.status
        or 0
    ) or 0

    local success = response.Success

    if success == nil then
        success = statusCode >= 200 and statusCode < 300
    end

    return {
        Success = success == true,

        StatusCode = statusCode,

        Body = tostring(
            response.Body
            or response.body
            or response.ResponseBody
            or response.responseBody
            or ""
        ),
    }, nil
end

local function FormatApiError(decoded, fallback)
    if type(decoded) ~= "table" then
        return tostring(fallback or "Unknown API error.")
    end

    local code = Clean(decoded.error or decoded.code):lower()
    local message = Clean(decoded.message)

    local messages = {
        invalid_key = "The key is invalid.",

        key_not_found = "The key is invalid.",

        missing_key = "Enter your HOLY key.",

        license_expired = "This key has expired.",

        license_revoked = "This key has been revoked.",

        license_paused = "This key is currently paused.",

        account_limit_reached = "This key has no Roblox account slots remaining.",

        product_not_allowed = "This key cannot access HOLY Core.",

        staff_access_required = "The dev loader requires a Staff or Owner key.",

        account_not_linked = "This Roblox account is not linked to the key.",

        invalid_access_token = "The temporary access token was rejected.",

        github_source_fetch_failed = "The private dev source could not be downloaded.",

        source_fetch_failed = "The private dev source could not be downloaded.",
    }

    return messages[code]
        or (message ~= "" and message)
        or (code ~= "" and code)
        or tostring(fallback or "Unknown API error.")
end

local function ActivateKey(key)
    local cleanKey = Clean(key):upper()

    if cleanKey == "" then
        return nil, "Enter your HOLY Owner or Staff key."
    end

    local response, requestError = SendRequest({
        Url = API .. "/v1/license/activate",

        Method = "POST",

        Headers = {
            ["Content-Type"] = "application/json",

            ["Accept"] = "application/json",

            ["Accept-Encoding"] = "identity",

            ["Cache-Control"] = "no-cache",
        },

        Body = HttpService:JSONEncode({
            Key = cleanKey,

            Product = PRODUCT,

            RobloxUserId = tonumber(LocalPlayer.UserId) or 0,

            RobloxUsername = tostring(LocalPlayer.Name),

            PlaceId = tostring(game.PlaceId),

            UniverseId = tostring(game.GameId),
        }),
    })

    if response == nil then
        return nil, "Activation request failed: " .. tostring(requestError)
    end

    local decoded = DecodeJson(response.Body)

    if response.Success ~= true
    or type(decoded) ~= "table"
    or decoded.ok ~= true then

        return nil, FormatApiError(
            decoded,
            "Activation failed with HTTP " .. tostring(response.StatusCode)
        )
    end

    local role = Clean(
        decoded.role
        or decoded.Role
        or "premium"
    ):lower()

    if role ~= "staff" and role ~= "owner" then
        return nil, "The dev loader requires a Staff or Owner key."
    end

    local token = Clean(
        decoded.accessToken
        or decoded.access_token
        or decoded.token
    )

    if token == "" then
        return nil, "The API did not return an access token."
    end

    return {
        Key = cleanKey,

        Role = role,

        Token = token,

        Activation = decoded,
    }, nil
end

local function DownloadDevSource(session)
    local response, requestError = SendRequest({
        Url = API .. SOURCE_ROUTE,

        Method = "GET",

        Headers = {
            ["Authorization"] = "Bearer " .. session.Token,

            ["Accept"] = "text/plain",

            ["Accept-Encoding"] = "identity",

            ["Cache-Control"] = "no-cache",
        },
    })

    if response == nil then
        return nil, "Source request failed: " .. tostring(requestError)
    end

    if response.Success ~= true then
        return nil, FormatApiError(
            DecodeJson(response.Body),
            "Source request failed with HTTP " .. tostring(response.StatusCode)
        )
    end

    local source = tostring(response.Body or "")

    if source:sub(1, 3) == "\239\187\191" then
        source = source:sub(4)
    end

    if source == "" then
        return nil, "The development source response was empty."
    end

    local preview = source:sub(1, 500):lower()

    if preview:find("<!doctype html", 1, true)
    or preview:find("<html", 1, true) then

        return nil, "The source route returned HTML instead of Lua."
    end

    if source:find(
        "-- HOLY LICENSE MARKER:",
        1,
        true
    ) ~= 1 then

        return nil, "The private source license marker is missing."
    end

    if preview:find(
        "-- holy source channel: dev",
        1,
        true
    ) == nil then

        return nil, "The API returned the wrong source channel."
    end

    return source, nil
end

local function InstallAuth(session)
    local activation = session.Activation
    local serverFeatures = activation.features or activation.Features
    local features = {}

    if type(serverFeatures) == "table" then
        for featureName, enabled in pairs(serverFeatures) do
            features[featureName] = enabled
        end
    end

    local licenseId = activation.licenseId or activation.LicenseId or ""

    local auth = {
        ok = true,

        Valid = true,

        Dev = true,

        Public = false,

        Product = activation.product
            or activation.Product
            or PRODUCT,

        Plan = session.Role,

        Role = session.Role,

        role = session.Role,

        KeyPrefix = activation.keyPrefix
            or activation.KeyPrefix
            or "",

        LicenseId = licenseId,

        SessionId = table.concat({
            "v2",

            tostring(
                licenseId ~= ""
                and licenseId
                or "license"
            ),

            tostring(LocalPlayer.UserId),

            tostring(os.time()),
        }, "_"),

        RobloxUserId = tonumber(LocalPlayer.UserId) or 0,

        RobloxUsername = tostring(LocalPlayer.Name),

        MaxAccounts = tonumber(
            activation.maxAccounts
            or activation.MaxAccounts
            or 0
        ) or 0,

        AccountsUsed = tonumber(
            activation.accountsUsed
            or activation.AccountsUsed
            or 0
        ) or 0,

        ExpiresAt = tonumber(
            activation.expiresAt
            or activation.ExpiresAt
            or 0
        ) or 0,

        Features = features,

        features = features,
    }

    Environment.HOLY_AUTH = auth
    Environment.HOLY_DEV_MODE = true
    Environment.HOLY_PUBLIC_MODE = false
    Environment.HOLY_DEV_PRODUCT = PRODUCT
    Environment.HOLY_SOURCE_CHANNEL = "dev"
    Environment.HOLY_LICENSE_ROLE = session.Role

    _G.HOLY_AUTH = auth
    _G.HOLY_DEV_MODE = true
    _G.HOLY_PUBLIC_MODE = false
    _G.HOLY_DEV_PRODUCT = PRODUCT
    _G.HOLY_SOURCE_CHANNEL = "dev"
    _G.HOLY_LICENSE_ROLE = session.Role

    return auth
end

local function QueueAfterTeleport()
    local queueFunction = GetQueueFunction()

    if type(queueFunction) ~= "function" then
        return false, "queue_on_teleport is unavailable"
    end

    local reloadUrl =
        DEV_LOADER_URL
        .. "?t="
        .. tostring(os.time())

    local queuedCode =
        "task.wait(2)\n"
        .. "loadstring(game:HttpGet("
        .. string.format("%q", reloadUrl)
        .. ", true))()"

    local ok, queueError = pcall(
        queueFunction,
        queuedCode
    )

    return ok, ok and nil or tostring(queueError)
end

local function CompileSource(source)
    local compiler = loadstring or load

    if type(compiler) ~= "function" then
        return nil, "loadstring/load is unavailable."
    end

    local ok, chunk, compileError = pcall(
        compiler,
        source
    )

    if not ok then
        return nil, tostring(chunk)
    end

    if type(chunk) ~= "function" then
        return nil, tostring(
            compileError
            or chunk
            or "compiler returned nil"
        )
    end

    return chunk, nil
end

local function RunWithKey(key)
    local session, activationError = ActivateKey(key)

    if session == nil then
        return false, activationError
    end

    local source, sourceError = DownloadDevSource(session)

    if source == nil then
        return false, sourceError
    end

    local saved, saveError = SaveKey(session.Key)

    if not saved then
        warn(
            "[HOLY DEV] Key authenticated, but could not be saved:",
            tostring(saveError)
        )
    end

    local auth = InstallAuth(session)

    session.Key = nil
    session.Token = nil

    local queued, queueError = QueueAfterTeleport()

    if not queued then
        warn(
            "[HOLY DEV] Teleport queue unavailable:",
            tostring(queueError)
        )
    end

    print(
        "[HOLY DEV] Authenticated.",

        "Role:",
        tostring(auth.Role),

        "User:",
        tostring(LocalPlayer.Name),

        "Source: dev"
    )

    local chunk, compileError = CompileSource(source)

    if chunk == nil then
        return false, "Compile failed: " .. tostring(compileError)
    end

    local runOk, runError = pcall(chunk)

    if not runOk then
        return false, "Run failed: " .. tostring(runError)
    end

    return true, nil
end

local function AddCorner(instance, radius)
    local corner = Instance.new("UICorner")

    corner.CornerRadius = UDim.new(
        0,
        radius
    )

    corner.Parent = instance
end

local function CreateKeyWindow(initialKey, initialMessage)
    local parent = CoreGui

    if type(gethui) == "function" then
        local ok, result = pcall(gethui)

        if ok and typeof(result) == "Instance" then
            parent = result
        end
    end

    local oldGui = parent:FindFirstChild("HOLY_Dev_Key_UI")

    if oldGui then
        oldGui:Destroy()
    end

    local gui = Instance.new("ScreenGui")

    gui.Name = "HOLY_Dev_Key_UI"

    gui.IgnoreGuiInset = true

    gui.ResetOnSpawn = false

    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if type(syn) == "table"
    and type(syn.protect_gui) == "function" then

        pcall(
            syn.protect_gui,
            gui
        )
    end

    gui.Parent = parent

    local window = Instance.new("Frame")

    window.AnchorPoint = Vector2.new(
        0.5,
        0.5
    )

    window.Position = UDim2.fromScale(
        0.5,
        0.5
    )

    window.Size = UDim2.fromOffset(
        430,
        252
    )

    window.BackgroundColor3 = Color3.fromRGB(
        17,
        18,
        23
    )

    window.BorderSizePixel = 0

    window.Active = true

    window.Draggable = true

    window.Parent = gui

    AddCorner(
        window,
        12
    )

    local accent = Instance.new("Frame")

    accent.Size = UDim2.new(
        1,
        0,
        0,
        4
    )

    accent.BackgroundColor3 = Color3.fromRGB(
        205,
        54,
        72
    )

    accent.BorderSizePixel = 0

    accent.Parent = window

    local title = Instance.new("TextLabel")

    title.Position = UDim2.fromOffset(
        24,
        20
    )

    title.Size = UDim2.new(
        1,
        -75,
        0,
        30
    )

    title.BackgroundTransparency = 1

    title.Font = Enum.Font.GothamBold

    title.Text = "HOLY DEV ACCESS"

    title.TextColor3 = Color3.fromRGB(
        245,
        246,
        250
    )

    title.TextSize = 20

    title.TextXAlignment = Enum.TextXAlignment.Left

    title.Parent = window

    local close = Instance.new("TextButton")

    close.AnchorPoint = Vector2.new(
        1,
        0
    )

    close.Position = UDim2.new(
        1,
        -18,
        0,
        17
    )

    close.Size = UDim2.fromOffset(
        32,
        32
    )

    close.BackgroundColor3 = Color3.fromRGB(
        28,
        30,
        38
    )

    close.BorderSizePixel = 0

    close.Font = Enum.Font.GothamBold

    close.Text = "X"

    close.TextColor3 = Color3.fromRGB(
        190,
        193,
        205
    )

    close.TextSize = 14

    close.Parent = window

    AddCorner(
        close,
        8
    )

    local subtitle = Instance.new("TextLabel")

    subtitle.Position = UDim2.fromOffset(
        24,
        56
    )

    subtitle.Size = UDim2.new(
        1,
        -48,
        0,
        34
    )

    subtitle.BackgroundTransparency = 1

    subtitle.Font = Enum.Font.Gotham

    subtitle.Text =
        "Enter an Owner or Staff key. Valid keys are saved automatically."

    subtitle.TextColor3 = Color3.fromRGB(
        155,
        159,
        175
    )

    subtitle.TextSize = 13

    subtitle.TextWrapped = true

    subtitle.TextXAlignment = Enum.TextXAlignment.Left

    subtitle.Parent = window

    local keyBox = Instance.new("TextBox")

    keyBox.Position = UDim2.fromOffset(
        24,
        101
    )

    keyBox.Size = UDim2.new(
        1,
        -48,
        0,
        46
    )

    keyBox.BackgroundColor3 = Color3.fromRGB(
        24,
        26,
        33
    )

    keyBox.BorderSizePixel = 0

    keyBox.ClearTextOnFocus = false

    keyBox.Font = Enum.Font.Code

    keyBox.PlaceholderText =
        "HOLY-XXXX-XXXX-XXXX-XXXX"

    keyBox.PlaceholderColor3 = Color3.fromRGB(
        103,
        107,
        123
    )

    keyBox.Text =
        Clean(initialKey):upper()

    keyBox.TextColor3 = Color3.fromRGB(
        238,
        239,
        244
    )

    keyBox.TextSize = 15

    keyBox.TextXAlignment = Enum.TextXAlignment.Left

    keyBox.Parent = window

    AddCorner(
        keyBox,
        8
    )

    local padding = Instance.new("UIPadding")

    padding.PaddingLeft = UDim.new(
        0,
        14
    )

    padding.PaddingRight = UDim.new(
        0,
        14
    )

    padding.Parent = keyBox

    local activate = Instance.new("TextButton")

    activate.Position = UDim2.fromOffset(
        24,
        159
    )

    activate.Size = UDim2.new(
        1,
        -48,
        0,
        42
    )

    activate.BackgroundColor3 = Color3.fromRGB(
        188,
        43,
        61
    )

    activate.BorderSizePixel = 0

    activate.Font = Enum.Font.GothamBold

    activate.Text = "ACTIVATE DEV KEY"

    activate.TextColor3 = Color3.fromRGB(
        255,
        255,
        255
    )

    activate.TextSize = 14

    activate.Parent = window

    AddCorner(
        activate,
        8
    )

    local status = Instance.new("TextLabel")

    status.Position = UDim2.fromOffset(
        24,
        211
    )

    status.Size = UDim2.new(
        1,
        -48,
        0,
        24
    )

    status.BackgroundTransparency = 1

    status.Font = Enum.Font.Gotham

    status.Text =
        Clean(initialMessage)

    status.TextColor3 = Color3.fromRGB(
        175,
        178,
        190
    )

    status.TextSize = 12

    status.TextTruncate =
        Enum.TextTruncate.AtEnd

    status.TextXAlignment =
        Enum.TextXAlignment.Left

    status.Parent = window

    local busy = false

    local function SetStatus(text, failed)
        status.Text = tostring(text or "")

        status.TextColor3 = failed
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
        if busy then
            return
        end

        local key =
            Clean(keyBox.Text):upper()

        if key == "" then
            SetStatus(
                "Enter your HOLY Owner or Staff key.",
                true
            )

            return
        end

        busy = true

        keyBox.Text = key

        activate.Active = false

        activate.AutoButtonColor = false

        activate.Text =
            "AUTHENTICATING..."

        SetStatus(
            "Checking license and private dev access...",
            false
        )

        task.spawn(function()
            local success, runError =
                RunWithKey(key)

            if success then
                SetStatus(
                    "Authenticated. Loading HOLY Dev...",
                    false
                )

                task.wait(0.15)

                if gui.Parent then
                    gui:Destroy()
                end

                return
            end

            busy = false

            activate.Active = true

            activate.AutoButtonColor = true

            activate.Text =
                "ACTIVATE DEV KEY"

            SetStatus(
                tostring(runError),
                true
            )

            warn(
                "[HOLY DEV]",
                tostring(runError)
            )
        end)
    end

    close.MouseButton1Click:Connect(function()
        Environment.HOLY_DEV_LOADER_RUNNING = false

        gui:Destroy()
    end)

    activate.MouseButton1Click:Connect(
        Submit
    )

    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            Submit()
        end
    end)
end

local savedKey = ReadSavedKey()

if savedKey ~= "" then
    print(
        "[HOLY DEV] Saved key found. Authenticating..."
    )

    local success, runError =
        RunWithKey(savedKey)

    if success then
        return
    end

    warn(
        "[HOLY DEV] Saved key failed:",
        tostring(runError)
    )

    CreateKeyWindow(
        savedKey,
        tostring(runError)
    )

    return
end

CreateKeyWindow(
    "",
    "Paste your Owner or Staff key to continue."
)
