using Microsoft.AspNetCore.Mvc;
using AuthService.Repositories;
using AuthService.Models;
using AuthService.Dtos;
using FirebaseAdmin.Auth;
using System.Net.Http.Json;

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

        // ✅ Đăng ký user mới (qua Firebase)
        [HttpPost("signup")]
        public async Task<IActionResult> SignUp([FromBody] SignUpRequest request)
        {
            try
            {
                var firebaseUser = await _firebaseAuthService.CreateUserAsync(request.Email, request.Password, request.DisplayName);

                var existingUser = await _authUserRepository.GetByFirebaseUidAsync(firebaseUser.Uid);
                if (existingUser != null)
                    return Conflict("User already exists.");

                var authUser = new AuthUser
                {
                    FirebaseUid = firebaseUser.Uid,
                    Email = firebaseUser.Email,
                    DisplayName = firebaseUser.DisplayName,
                    Role = "User",
                    CreatedAt = DateTime.UtcNow
                };
                await _authUserRepository.AddAsync(authUser);

                return Ok(new { uid = firebaseUser.Uid, email = firebaseUser.Email });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ SignUp error: {ex.Message}");
                return BadRequest(new { error = ex.Message });
            }
        }

        // ✅ Xác thực token và đồng bộ user sang UserService
        [HttpPost("verifyToken")]
        public async Task<IActionResult> VerifyToken([FromBody] TokenRequest request)
        {
            try
            {
                var uid = await _firebaseAuthService.VerifyIdTokenAsync(request.IdToken);
                var user = await _authUserRepository.GetByFirebaseUidAsync(uid);

                if (user == null)
                {
                    // Nếu user chưa có trong Auth DB → tạo mới
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

                    // 🔹 Gọi sang UserService để tạo user trống
                    var http = _httpClientFactory.CreateClient();
                    var newUser = new { firebaseUid = firebaseUser.Uid };

                    try
                    {
                        var response = await http.PostAsJsonAsync("http://localhost:8082/api/users/sync", newUser);
                        if (!response.IsSuccessStatusCode)
                        {
                            Console.WriteLine($"⚠️ Failed to sync user to UserService: {response.StatusCode}");
                        }
                        else
                        {
                            Console.WriteLine($"✅ Synced user {firebaseUser.Uid} to UserService");
                        }
                    }
                    catch (HttpRequestException ex)
                    {
                        Console.WriteLine($"🚫 Error calling UserService: {ex.Message}");
                    }
                }

                return Ok(new { uid = user.FirebaseUid, email = user.Email, role = user.Role });
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
