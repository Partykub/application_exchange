String? validatorPassword(inputpassword) {
  if (inputpassword!.isEmpty) {
    return 'กรุณาระบุรหัสผ่าน';
  }
  if (inputpassword.length < 8 || inputpassword.length > 20) {
    return 'รหัสผ่านต้องมีความยาวระหว่าง 8 ถึง 20 ตัว';
  }

  if (!RegExp(r'^(?=.*[A-Z])').hasMatch(inputpassword)) {
    return 'รหัสผ่านต้องมีพิมพ์ใหญ่อย่างน้อย 1 ตัว';
  }

  if (!RegExp(r'\d').hasMatch(inputpassword)) {
    return 'รหัสผ่านต้องมีตัวเลขอย่างน้อย 1 ตัว';
  }

  if (!RegExp(r'[A-Za-z0-9@#$%&*+]').hasMatch(inputpassword)) {
    return 'รหัสผ่านต้องใช้ได้แค่ ภาษาอังกฤษ, ตัวเลข, และ @#%&*+';
  }
  return null;
}
