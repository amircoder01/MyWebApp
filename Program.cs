var builder = WebApplication.CreateBuilder(args);

// Lägg till tjänster för kontroller och vyer
builder.Services.AddControllersWithViews();

var app = builder.Build();

// Konfigurera HTTP-begärningspipelin
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // Standard HSTS-värde är 30 dagar. Du kanske vill ändra detta för produktionsscenarier.
    app.UseHsts();
}

// Aktivera HTTPS-omdirigering om du vill
app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
