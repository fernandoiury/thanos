local g = import '../lib/thanos-grafana-builder/builder.libsonnet';

{
  local thanos = self,
  compactor+:: {
    jobPrefix: error 'must provide job prefix for Thanos Compactor dashboard',
    selector: error 'must provide selector for Thanos Compactor dashboard',
    title: error 'must provide title for Thanos Compactor dashboard',
  },
  grafanaDashboards+:: {
    'compactor.json':
      g.dashboard(thanos.compactor.title)
      .addRow(
        g.row('Group Compaction')
        .addPanel(
          g.panel(
            'Rate',
            'Shows rate of execution for compactions against blocks that are stored in the bucket by compaction group.'
          ) +
          g.queryPanel(
            'sum(rate(thanos_compact_group_compactions_total{namespace="$namespace",job=~"$job"}[$interval])) by (job, group)',
            'compaction {{job}} {{group}}'
          ) +
          g.stack
        )
        .addPanel(
          g.panel(
            'Errors',
            'Shows ratio of errors compared to the total number of executed compactions against blocks that are stored in the bucket.'
          ) +
          g.qpsErrTotalPanel(
            'thanos_compact_group_compactions_failures_total{namespace="$namespace",job=~"$job"}',
            'thanos_compact_group_compactions_total{namespace="$namespace",job=~"$job"}',
          )
        )
      )
      .addRow(
        g.row('Downsample')
        .addPanel(
          g.panel(
            'Rate',
            'Shows rate of execution for downsampling against blocks that are stored in the bucket by compaction group.'
          ) +
          g.queryPanel(
            'sum(rate(thanos_compact_downsample_total{namespace="$namespace",job=~"$job"}[$interval])) by (job, group)',
            'downsample {{job}} {{group}}'
          ) +
          g.stack
        )
        .addPanel(
          g.panel('Errors', 'Shows ratio of errors compared to the total number of executed downsampling against blocks that are stored in the bucket.') +
          g.qpsErrTotalPanel(
            'thanos_compact_downsample_failed_total{namespace="$namespace",job=~"$job"}',
            'thanos_compact_downsample_total{namespace="$namespace",job=~"$job"}',
          )
        )
      )
      .addRow(
        g.row('Garbage Collection')
        .addPanel(
          g.panel(
            'Rate',
            'Shows rate of execution for removals of blocks if their data is available as part of a block with a higher compaction level.'
          ) +
          g.queryPanel(
            'sum(rate(thanos_compact_garbage_collection_total{namespace="$namespace",job=~"$job"}[$interval])) by (job)',
            'garbage collection {{job}}'
          ) +
          g.stack
        )
        .addPanel(
          g.panel('Errors', 'Shows ratio of errors compared to the total number of executed garbage collections.') +
          g.qpsErrTotalPanel(
            'thanos_compact_garbage_collection_failures_total{namespace="$namespace",job=~"$job"}',
            'thanos_compact_garbage_collection_total{namespace="$namespace",job=~"$job"}',
          )
        )
        .addPanel(
          g.panel('Duration', 'Shows how long has it taken to execute garbage collection in quantiles.') +
          g.latencyPanel('thanos_compact_garbage_collection_duration_seconds', 'namespace="$namespace",job=~"$job"')
        )
      )
      .addRow(
        g.row('Sync Meta')
        .addPanel(
          g.panel(
            'Rate',
            'Shows rate of execution for all meta files from blocks in the bucket into the memory.'
          ) +
          g.queryPanel(
            'sum(rate(thanos_blocks_meta_syncs_total{namespace="$namespace",job=~"$job"}[$interval])) by (job)',
            'sync {{job}}'
          ) +
          g.stack
        )
        .addPanel(
          g.panel('Errors', 'Shows ratio of errors compared to the total number of executed meta file sync.') +
          g.qpsErrTotalPanel(
            'thanos_blocks_meta_sync_failures_total{namespace="$namespace",job=~"$job"}',
            'thanos_blocks_meta_syncs_total{namespace="$namespace",job=~"$job"}',
          )
        )
        .addPanel(
          g.panel('Duration', 'Shows how long has it taken to execute meta file sync, in quantiles.') +
          g.latencyPanel('thanos_blocks_meta_sync_duration_seconds', 'namespace="$namespace",job=~"$job"')
        )
      )
      .addRow(
        g.row('Object Store Operations')
        .addPanel(
          g.panel('Rate', 'Shows rate of execution for operations against the bucket.') +
          g.queryPanel(
            'sum(rate(thanos_objstore_bucket_operations_total{namespace="$namespace",job=~"$job"}[$interval])) by (job, operation)',
            '{{job}} {{operation}}'
          ) +
          g.stack
        )
        .addPanel(
          g.panel('Errors', 'Shows ratio of errors compared to the total number of executed operations against the bucket.') +
          g.qpsErrTotalPanel(
            'thanos_objstore_bucket_operation_failures_total{namespace="$namespace",job=~"$job"}',
            'thanos_objstore_bucket_operations_total{namespace="$namespace",job=~"$job"}',
          )
        )
        .addPanel(
          g.panel('Duration', 'Shows how long has it taken to execute operations against the bucket, in quantiles.') +
          g.latencyPanel('thanos_objstore_bucket_operation_duration_seconds', 'namespace="$namespace",job=~"$job"')
        )
      )
      .addRow(
        g.resourceUtilizationRow()
      ) +
      g.template('namespace', thanos.dashboard.namespaceQuery) +
      g.template('job', 'up', 'namespace="$namespace",%(selector)s' % thanos.compactor, true, '%(jobPrefix)s.*' % thanos.compactor) +
      g.template('pod', 'kube_pod_info', 'namespace="$namespace",created_by_name=~"%(jobPrefix)s.*"' % thanos.compactor, true, '.*'),

    __overviewRows__+:: [
      g.row('Compactor')
      .addPanel(
        g.panel(
          'Compaction Rate',
          'Shows rate of execution for compactions against blocks that are stored in the bucket by compaction group.'
        ) +
        g.queryPanel(
          'sum(rate(thanos_compact_group_compactions_total{namespace="$namespace",%(selector)s}[$interval])) by (job)' % thanos.compactor,
          'compaction {{job}}'
        ) +
        g.stack +
        g.addDashboardLink(thanos.compactor.title)
      )
      .addPanel(
        g.panel(
          'Compaction Errors',
          'Shows ratio of errors compared to the total number of executed compactions against blocks that are stored in the bucket.'
        ) +
        g.qpsErrTotalPanel(
          'thanos_compact_group_compactions_failures_total{namespace="$namespace",%(selector)s}' % thanos.compactor,
          'thanos_compact_group_compactions_total{namespace="$namespace",%(selector)s}' % thanos.compactor,
        ) +
        g.addDashboardLink(thanos.compactor.title)
      ) +
      g.collapse,
    ],
  },
}
