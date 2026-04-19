import 'package:flutter/material.dart';

class TermsOfUseBottomSheet extends StatelessWidget {
  const TermsOfUseBottomSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => const TermsOfUseBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Pill indicator
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Terms of Use',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2C59),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    children: const [
                      Text(
                        '''TERMS OF USE FOR IMATE

Effective Date: [Insert Date]
Last Updated: [Insert Date]

Welcome to iMate. These Terms of Use (“Terms”) govern your access to and use of the iMate mobile application, related services, content, features, and software (collectively, the “Service”) provided by [Your Name / Team Name / Company Name] (“we,” “us,” or “our”).

By downloading, accessing, or using iMate, you agree to be bound by these Terms. If you do not agree to these Terms, please do not use the Service.

1. About iMate
iMate is a personal assistant application designed to help users manage daily activities such as personal accounts and settings, expense tracking, wallets, shopping schedules, meal planning, health and wellness logs, AI-assisted interactions, and smart home IoT controls.

Some features may rely on third-party services, device permissions, internet connectivity, or compatible hardware.

2. Eligibility
You must be at least 13 years old, or the minimum legal age required in your jurisdiction to use the Service. If you are under the age of majority, you may use iMate only with the involvement and permission of a parent or legal guardian.

By using the Service, you represent that:
- you have the legal capacity to accept these Terms;
- the information you provide is accurate and current; and
- your use of the Service complies with applicable laws and regulations.

3. Account Registration and Security
To use certain features, you may need to create an account or sign in using email/password or a supported third-party login provider such as Google Sign-In.

You are responsible for:
- maintaining the confidentiality of your account credentials;
- all activities that occur under your account; and
- notifying us promptly if you suspect unauthorized access or misuse of your account.

We may suspend or terminate accounts that are used unlawfully, fraudulently, abusively, or in violation of these Terms.

4. Privacy and Data Use
Your use of iMate is also subject to our Privacy Policy, which explains how we collect, use, store, and share your information.

Because iMate may process personal, health-related, lifestyle, device, and usage information, you acknowledge that:
- some information you provide may be sensitive;
- certain app functions require access to device permissions such as camera, storage, notifications, sensors, or motion/fitness data;
- you are responsible for reviewing permission prompts and granting only the permissions you want to allow.

We will use your information only as described in our Privacy Policy and as necessary to provide the Service.

5. Health and Wellness Features
iMate may include health and wellness features such as step tracking, hydration logging, sleep logging, activity tracking, food image analysis, nutrition estimation, health dashboards, and meal planning.

These features are provided for general informational, wellness, and personal lifestyle support purposes only.

iMate:
- is not a medical device;
- does not provide medical advice, diagnosis, treatment, or emergency services;
- does not guarantee the accuracy of health, nutrition, or wellness outputs; and
- should not be relied on as a substitute for professional medical judgment.

You should always consult a qualified healthcare professional before making medical, nutritional, or treatment decisions. If you believe you are having a medical emergency, contact emergency services immediately.

6. AI Features
iMate may offer AI-powered functions, including chat assistance, meal suggestions, and food image analysis. These features may rely on third-party AI providers.

You understand and agree that:
- AI-generated responses may be inaccurate, incomplete, delayed, or inappropriate;
- AI outputs are generated automatically and may not reflect professional advice;
- you are solely responsible for reviewing and evaluating any AI-generated content before relying on it.

You must not use iMate’s AI features for high-risk decisions, including medical emergencies, legal decisions, financial decisions, or any use where errors could cause harm.

7. Wallet, Expense, and Shopping Features
iMate may allow you to track expenses, manage wallets, create shopping schedules, and use automatic deduction logic for selected wallet records.

These features are intended for personal budgeting, planning, and record-keeping only.

Unless explicitly stated otherwise:
- wallets in iMate are not bank accounts;
- iMate is not a payment processor, e-wallet provider, money transmitter, or financial institution;
- automatic deduction features represent internal app records and do not guarantee actual payment execution in the real world.

You are solely responsible for verifying your financial transactions, balances, purchases, and payment obligations outside the app.

8. IoT and Device Control Features
iMate may support interaction with compatible IoT devices, such as lights, fans, and environmental sensors, through supported communication services.

By using IoT features, you acknowledge that:
- IoT functionality depends on third-party hardware, connectivity, and network availability;
- commands may fail, be delayed, or behave unexpectedly;
- you are responsible for using connected devices safely and lawfully.

You must not use iMate in situations where device malfunction, delay, or inattention could lead to injury, damage, or safety risks.

9. User Content
You may submit, store, upload, or generate content through iMate, including profile information, text entries, meal records, health logs, schedules, and images (“User Content”).

You retain ownership of your User Content. However, by submitting User Content through the Service, you grant us a limited, non-exclusive, revocable license to host, store, process, reproduce, and display that content solely as necessary to operate, maintain, improve, and provide the Service to you.

You are solely responsible for your User Content and represent that:
- you own it or have the right to use it;
- it does not violate any law or the rights of others; and
- it does not contain harmful, abusive, deceptive, or unlawful material.

10. Prohibited Conduct
You agree not to:
- use the Service for any unlawful, harmful, fraudulent, or deceptive purpose;
- interfere with or disrupt the Service, servers, networks, or security features;
- attempt to access data or accounts that do not belong to you;
- reverse engineer, copy, modify, distribute, or exploit the Service except as permitted by law;
- upload malware, harmful code, or malicious content;
- use the Service to harass, abuse, defame, threaten, or infringe the rights of others;
- misuse AI outputs or present them as verified professional advice;
- use the app while driving or in any unsafe situation requiring full attention.

11. Third-Party Services
The Service may integrate with or depend on third-party services such as Firebase, Google Sign-In, AI platforms, analytics tools, notification services, cloud storage, MQTT brokers, or device manufacturers.

We do not control and are not responsible for:
- the availability, accuracy, or performance of third-party services;
- the acts or omissions of third-party providers; or
- any loss caused by third-party systems, outages, policies, or security events.

Your use of third-party services may also be subject to their own terms and privacy policies.

12. Availability and Changes
We may update, modify, suspend, or discontinue any part of iMate at any time, with or without notice, including features, integrations, and functionality.

We do not guarantee that the Service will always be available, uninterrupted, secure, or error-free.

13. Intellectual Property
The Service, including its software, branding, design, interface, text, graphics, logos, and other non-user content, is owned by or licensed to us and is protected by applicable intellectual property laws.

Except as expressly permitted in these Terms, you may not copy, reproduce, distribute, modify, create derivative works from, publicly display, or commercially exploit any part of the Service.

14. Disclaimer of Warranties
To the maximum extent permitted by law, the Service is provided on an “as is” and “as available” basis.

We make no warranties or representations, express or implied, regarding:
- accuracy, reliability, completeness, or usefulness of the Service;
- uninterrupted or error-free operation;
- security or freedom from harmful components; or
- fitness for a particular purpose.

This disclaimer applies especially to AI-generated content, health estimates, nutrition analysis, shopping reminders, financial records, and IoT controls.

15. Limitation of Liability
To the maximum extent permitted by law, we will not be liable for any indirect, incidental, special, consequential, exemplary, or punitive damages, including loss of data, loss of profits, loss of savings, business interruption, personal injury, or property damage arising out of or related to your use of or inability to use the Service.

Our total liability for any claim relating to the Service will not exceed the amount you paid us, if any, for use of the Service during the twelve (12) months before the event giving rise to the claim.

Nothing in these Terms excludes liability that cannot be excluded under applicable law.

16. Indemnification
You agree to indemnify and hold harmless [Your Name / Team Name / Company Name] and its affiliates, contributors, and service providers from and against any claims, liabilities, damages, losses, and expenses arising out of:
- your use or misuse of the Service;
- your violation of these Terms;
- your User Content; or
- your violation of any law or the rights of any third party.

17. Suspension and Termination
We may suspend, restrict, or terminate your access to the Service at any time if:
- you violate these Terms;
- we suspect fraud, abuse, or unlawful conduct;
- required by law; or
- continued operation of your account creates risk to the Service or other users.

You may stop using the Service at any time. Account deletion requests may be handled according to our Privacy Policy and applicable data retention obligations.

18. Governing Law
These Terms are governed by the laws of [Insert Country / Jurisdiction], without regard to conflict of law principles.

Any disputes arising out of or relating to these Terms or the Service shall be subject to the exclusive jurisdiction of the courts located in [Insert City / Country], unless applicable law requires otherwise.

19. Changes to These Terms
We may revise these Terms from time to time. If we make material changes, we may provide notice through the app, website, or other reasonable means.

Your continued use of iMate after updated Terms become effective means you accept the revised Terms.

20. Contact Information
If you have questions about these Terms, please contact us at:

Name: [Your Name / Team Name / Company Name]
Email: [Your Support Email]
Address: [Optional Address]
Website: [Optional Website]

By using iMate, you acknowledge that you have read, understood, and agreed to these Terms of Use.
''',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43618E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'I Agree',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
