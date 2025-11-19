using Microsoft.AspNetCore.Mvc;
using AuthService.Repositories;
using AuthService.Models;
using FirebaseAdmin.Auth;
using System.Net.Http.Json;
using AuthService.Dtos;

namespace AuthService.Services
{
    [ApiController]
    [Route("api/auth")]
    public class AuthUserController : ControllerBase
    {
        private readonly IAuthUserRepository _authUserRepository;
        private readonly FirebaseAuthService _firebaseAuthService;
        private readonly IHttpClientFactory _httpClientFactory;

        public AuthUserController(
            IAuthUserRepository authUserRepository,
            FirebaseAuthService firebaseAuthService,
            IHttpClientFactory httpClientFactory)
        {
            _authUserRepository = authUserRepository;
            _firebaseAuthService = firebaseAuthService;
            _httpClientFactory = httpClientFactory;
        }

        // ✅ Đăng ký user mới và đồng bộ sang UserService
        [HttpPost("signup")]
        public async Task<IActionResult> SignUp([FromBody] SignUpRequest request)
        {
            try
            {
                // 1️⃣ Tạo user trên Firebase
                var firebaseUser = await _firebaseAuthService.CreateUserAsync(
                    request.Email, request.Password, request.DisplayName);

                // 2️⃣ Kiểm tra user đã tồn tại trong Auth DB chưa
                var existingUser = await _authUserRepository.GetByFirebaseUidAsync(firebaseUser.Uid);
                if (existingUser != null)
                    return Conflict("User already exists.");

                // 3️⃣ Thêm user vào Auth DB
                var authUser = new AuthUser
                {
                    FirebaseUid = firebaseUser.Uid,
                    Email = firebaseUser.Email,
                    DisplayName = firebaseUser.DisplayName,
                    Role = "User",
                    CreatedAt = DateTime.UtcNow
                };
                await _authUserRepository.AddAsync(authUser);

                // 4️⃣ Đồng bộ user sang UserService
                var http = _httpClientFactory.CreateClient();
                var newUser = new
                {
                    firebaseUid = firebaseUser.Uid,
                    email = firebaseUser.Email,           // ✅ bắt buộc
                    fullName = firebaseUser.DisplayName   // ✅ tùy muốn
                };

                try
                {
                    var response = await http.PostAsJsonAsync("http://userservice:8082/api/users/sync", newUser);
                    if (!response.IsSuccessStatusCode)
                        Console.WriteLine($"⚠️ Failed to sync user to UserService: {response.StatusCode}");
                    else
                        Console.WriteLine($"✅ Synced user {firebaseUser.Uid} to UserService");
                }
                catch (HttpRequestException ex)
                {
                    Console.WriteLine($"🚫 Error calling UserService: {ex.Message}");
                }
                var token = await _firebaseAuthService.GenerateCustomTokenAsync(firebaseUser.Uid);
                return Ok(new
                {
                    uid = firebaseUser.Uid,
                    email = firebaseUser.Email,
                    displayName = firebaseUser.DisplayName ?? "",
                    token = token
                });

            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ SignUp error: {ex.Message}");
                return BadRequest(new { error = ex.Message });
            }
        }

        // ✅ Xác thực token gọn nhẹ
        [HttpPost("verifyToken")]
        public async Task<IActionResult> VerifyToken([FromBody] TokenRequest request)
        {
            try
            {
                // 1️⃣ Verify Firebase token
                var uid = await _firebaseAuthService.VerifyIdTokenAsync(request.IdToken);

                // 2️⃣ Kiểm tra Auth DB
                var user = await _authUserRepository.GetByFirebaseUidAsync(uid);
                bool isNewUser = false;

                if (user == null)
                {
                    // Tạo AuthUser mới nếu chưa tồn tại
                    var firebaseUser = await FirebaseAuth.DefaultInstance.GetUserAsync(uid);
                    user = new AuthUser
                    {
                        FirebaseUid = firebaseUser.Uid,
                        Email = firebaseUser.Email,
                        DisplayName = firebaseUser.DisplayName,
                        Role = "User",
                        CreatedAt = DateTime.UtcNow
                    };
                    await _authUserRepository.AddAsync(user);
                    isNewUser = true;

                    Console.WriteLine($"✅ Created new AuthUser for uid={uid}");
                }

                // 3️⃣ Luôn đồng bộ sang UserService
                try
                {
                    var http = _httpClientFactory.CreateClient();
                    var syncData = new
                    {
                        firebaseUid = user.FirebaseUid,
                        email = user.Email,
                        fullName = user.DisplayName
                    };

                    var response = await http.PostAsJsonAsync("http://userservice:8082/api/users/sync", syncData);
                    if (response.IsSuccessStatusCode)
                    {
                        Console.WriteLine($"✅ Synced user {user.FirebaseUid} to UserService");
                    }
                    else
                    {
                        var body = await response.Content.ReadAsStringAsync();
                        Console.WriteLine($"⚠️ Failed to sync user {user.FirebaseUid}: {response.StatusCode}, {body}");
                    }
                }
                catch (HttpRequestException ex)
                {
                    Console.WriteLine($"🚫 Error calling UserService: {ex.Message}");
                }

                return Ok(new { uid = user.FirebaseUid, email = user.Email, role = user.Role, isNewUser });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Token verification failed: {ex.Message}");
                return Unauthorized(new { error = ex.Message });
            }
        }

        public class TokenRequest
        {
            public string IdToken { get; set; } = string.Empty;
        }
    }
}
