import os
import smtplib
import logging
from email.message import EmailMessage

# Lấy cấu hình từ biến môi trường
SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", 587))
SMTP_USERNAME = os.getenv("SMTP_USERNAME")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
FROM_EMAIL = os.getenv("FROM_EMAIL", SMTP_USERNAME)

def send_otp_email(to_email: str, otp_code: str, customer_name: str) -> bool:
    """
    Gửi email chứa mã OTP đến khách hàng.
    Trả về True nếu gửi thành công, False nếu thất bại.
    """
    if not SMTP_USERNAME or not SMTP_PASSWORD:
        logging.error("Chưa cấu hình SMTP_USERNAME hoặc SMTP_PASSWORD trong biến môi trường.")
        return False

    msg = EmailMessage()
    msg.set_content(
        f"Xin chào {customer_name},\n\n"
        f"Cảm ơn bạn đã đặt bàn tại nhà hàng của chúng tôi.\n"
        f"Mã xác nhận (OTP) của bạn là: {otp_code}\n\n"
        f"Mã này sẽ hết hạn trong vòng 5 phút.\n"
        f"Trân trọng,\n"
        f"ROS Restaurant"
    )

    msg["Subject"] = f"Mã xác nhận đặt bàn của bạn là {otp_code}"
    msg["From"] = FROM_EMAIL
    msg["To"] = to_email

    try:
        # Kết nối tới server SMTP
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()  # Bảo mật kết nối
        server.login(SMTP_USERNAME, SMTP_PASSWORD)
        server.send_message(msg)
        server.quit()
        logging.info(f"Đã gửi email OTP thành công tới {to_email}")
        return True
    except Exception as e:
        logging.error(f"Lỗi khi gửi email tới {to_email}: {e}")
        return False
