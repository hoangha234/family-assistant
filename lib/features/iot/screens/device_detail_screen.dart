import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/device_detail_cubit.dart';

class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DeviceDetailCubit(),
      child: const DeviceDetailView(),
    );
  }
}

class DeviceDetailView extends StatelessWidget {
  const DeviceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Detail')),
      body: Center(
        child: BlocBuilder<DeviceDetailCubit, DeviceDetailState>(
          builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('LED: ${state.ledStatus ? 'ON' : 'OFF'}'),
                Text('FAN: ${state.fanStatus ? 'ON' : 'OFF'}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<DeviceDetailCubit>().toggleLed(true),
                  child: const Text('LED ON'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      context.read<DeviceDetailCubit>().toggleLed(false),
                  child: const Text('LED OFF'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      context.read<DeviceDetailCubit>().toggleFan(true),
                  child: const Text('FAN ON'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      context.read<DeviceDetailCubit>().toggleFan(false),
                  child: const Text('FAN OFF'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
